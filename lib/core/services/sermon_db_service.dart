import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../l10n.dart';
import '../mock_data.dart';

/// One scripture reference captured during a sermon.
///
/// The structured fields ([bookId], [chapter], [verseStart], [verseEnd]) are
/// what make a reference tappable: they identify the exact passage no matter
/// which language the believer is reading in. [ref] is the English label kept
/// as a human-readable fallback (and for notes saved by older versions, whose
/// structured fields are recovered by parsing it).
class SermonRef {
  final String ref; // e.g. "John 3:16" or "Romans 8:28-30"
  final String text; // optional English preview text
  final int bookId; // canonical 1–66, 0 when unknown
  final int chapter; // 0 when unknown
  final int verseStart; // 0 = whole chapter
  final int verseEnd; // == verseStart for a single verse

  const SermonRef({
    required this.ref,
    this.text = '',
    this.bookId = 0,
    this.chapter = 0,
    this.verseStart = 0,
    this.verseEnd = 0,
  });

  /// True when this reference points at a real chapter of a real book.
  bool get canOpen =>
      bookId >= 1 && bookId <= MockBible.books.length && chapter >= 1;

  /// Display label in [lang] ('en'|'te'|'hi'), e.g. "యోహాను 3:16".
  String label(String lang) {
    if (!canOpen) return ref;
    final String name = localizedBookName(bookId, lang);
    final String tail = verseStart <= 0
        ? '$chapter'
        : (verseEnd > verseStart
            ? '$chapter:$verseStart-$verseEnd'
            : '$chapter:$verseStart');
    return '$name $tail';
  }

  Map<String, Object> toJson() => {
        'ref': ref,
        'text': text,
        'book': bookId,
        'chapter': chapter,
        'v1': verseStart,
        'v2': verseEnd,
      };

  factory SermonRef.fromJson(Map<String, dynamic> j) {
    final String ref = (j['ref'] as String?) ?? '';
    final String text = (j['text'] as String?) ?? '';
    final int book = (j['book'] as num?)?.toInt() ?? 0;
    if (book > 0) {
      return SermonRef(
        ref: ref,
        text: text,
        bookId: book,
        chapter: (j['chapter'] as num?)?.toInt() ?? 0,
        verseStart: (j['v1'] as num?)?.toInt() ?? 0,
        verseEnd: (j['v2'] as num?)?.toInt() ?? 0,
      );
    }
    return SermonRef._legacy(ref, text);
  }

  static final RegExp _legacyPattern =
      RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

  /// Recovers the structured fields of a reference saved as plain text
  /// ("John 3:16"). Unparseable text stays a non-openable label.
  factory SermonRef._legacy(String ref, String text) {
    final RegExpMatch? m = _legacyPattern.firstMatch(ref.trim());
    if (m != null) {
      final String name = m.group(1)!.trim().toLowerCase();
      final int index = MockBible.books
          .indexWhere((b) => b.englishName.toLowerCase() == name);
      if (index >= 0) {
        final int v1 = int.tryParse(m.group(3) ?? '') ?? 0;
        final int v2 = int.tryParse(m.group(4) ?? '') ?? v1;
        return SermonRef(
          ref: ref,
          text: text,
          bookId: index + 1,
          chapter: int.tryParse(m.group(2)!) ?? 0,
          verseStart: v1,
          verseEnd: v2 < v1 ? v1 : v2,
        );
      }
    }
    return SermonRef(ref: ref, text: text);
  }
}

/// A saved sermon note.
class SermonRecord {
  final int? id;
  final String title;
  final String preacher;
  final String service;
  final DateTime date;
  final List<String> points;
  final List<SermonRef> refs;
  final String body;
  final DateTime updatedAt;

  const SermonRecord({
    this.id,
    required this.title,
    required this.preacher,
    required this.service,
    required this.date,
    required this.points,
    required this.refs,
    required this.body,
    required this.updatedAt,
  });

  bool get isBlank =>
      title.trim().isEmpty &&
      preacher.trim().isEmpty &&
      body.trim().isEmpty &&
      points.isEmpty &&
      refs.isEmpty;

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'title': title,
        'preacher': preacher,
        'service': service,
        'date_ms': date.millisecondsSinceEpoch,
        'points': jsonEncode(points),
        'refs': jsonEncode(refs.map((r) => r.toJson()).toList()),
        'body': body,
        'updated_ms': updatedAt.millisecondsSinceEpoch,
      };

  factory SermonRecord.fromRow(Map<String, Object?> r) {
    List<String> points = const [];
    List<SermonRef> refs = const [];
    try {
      points = (jsonDecode((r['points'] as String?) ?? '[]') as List)
          .map((e) => e.toString())
          .toList();
      refs = (jsonDecode((r['refs'] as String?) ?? '[]') as List)
          .map((e) => SermonRef.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // A malformed JSON cell must never make the whole note unreadable.
    }
    return SermonRecord(
      id: r['id'] as int?,
      title: (r['title'] as String?) ?? '',
      preacher: (r['preacher'] as String?) ?? '',
      service: (r['service'] as String?) ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
          (r['date_ms'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
      points: points,
      refs: refs,
      body: (r['body'] as String?) ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (r['updated_ms'] as int?) ?? 0),
    );
  }
}

/// Writable SQLite store for the user's own sermon notes. Kept separate from
/// the read-only bundled Bible engine so a note can never touch scripture data.
///
/// Safety: on open it runs `PRAGMA integrity_check`; a database that fails is
/// moved aside as `sermon_notes.db.corrupt-<time>` (never deleted) and a fresh
/// one is created, so the app always starts and the damaged file stays
/// recoverable.
class SermonDbService {
  SermonDbService._();

  static final SermonDbService instance = SermonDbService._();

  static const String _dbName = 'sermon_notes.db';
  static const int _version = 1;

  Database? _db;
  Future<Database>? _opening;

  Future<Database> _open() {
    final existing = _db;
    if (existing != null && existing.isOpen) return Future.value(existing);
    return _opening ??= _openInternal().whenComplete(() => _opening = null);
  }

  Future<Database> _openInternal() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);

    Future<Database> openIt() => openDatabase(
          path,
          version: _version,
          onCreate: (db, v) async {
            await db.execute('''
              CREATE TABLE sermons (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                title      TEXT NOT NULL DEFAULT '',
                preacher   TEXT NOT NULL DEFAULT '',
                service    TEXT NOT NULL DEFAULT '',
                date_ms    INTEGER NOT NULL,
                points     TEXT NOT NULL DEFAULT '[]',
                refs       TEXT NOT NULL DEFAULT '[]',
                body       TEXT NOT NULL DEFAULT '',
                updated_ms INTEGER NOT NULL
              )''');
            await db.execute(
                'CREATE INDEX idx_sermons_updated ON sermons(updated_ms DESC)');
          },
        );

    Database db;
    try {
      db = await openIt();
      final check = await db.rawQuery('PRAGMA integrity_check');
      final ok = check.isNotEmpty && check.first.values.first == 'ok';
      if (!ok) throw const FormatException('integrity_check failed');
    } catch (_) {
      try {
        await _db?.close();
      } catch (_) {}
      final f = File(path);
      if (f.existsSync()) {
        await f.rename(
            '$path.corrupt-${DateTime.now().millisecondsSinceEpoch}');
      }
      db = await openIt();
    }
    return _db = db;
  }

  /// Inserts or updates [r]; returns the row id.
  Future<int> save(SermonRecord r) async {
    final db = await _open();
    if (r.id == null) {
      return db.insert('sermons', r.toRow());
    }
    await db.update('sermons', r.toRow(), where: 'id = ?', whereArgs: [r.id]);
    return r.id!;
  }

  /// Every saved sermon, newest service date first (ties: most recently
  /// edited first) — a clean chronological log.
  Future<List<SermonRecord>> all() async {
    final db = await _open();
    final rows =
        await db.query('sermons', orderBy: 'date_ms DESC, updated_ms DESC');
    return rows.map(SermonRecord.fromRow).toList();
  }

  /// The note that was edited most recently (what the notepad reopens on).
  Future<SermonRecord?> lastEdited() async {
    final db = await _open();
    final rows =
        await db.query('sermons', orderBy: 'updated_ms DESC', limit: 1);
    return rows.isEmpty ? null : SermonRecord.fromRow(rows.first);
  }

  Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('sermons', where: 'id = ?', whereArgs: [id]);
  }
}
