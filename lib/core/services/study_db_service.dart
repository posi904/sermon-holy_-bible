import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// A bookmarked or favourited verse, with its text in all three languages so
/// the saved lists show instantly in whichever language is being read.
class SavedVerse {
  const SavedVerse({
    required this.id,
    required this.kind,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.en,
    required this.te,
    required this.hi,
    required this.createdMs,
  });

  final int id;
  final String kind;
  final int bookId;
  final int chapter;
  final int verse;
  final String en;
  final String te;
  final String hi;
  final int createdMs;

  String textFor(String lang) {
    final String t = lang == 'te' ? te : (lang == 'hi' ? hi : en);
    return t.isNotEmpty ? t : (en.isNotEmpty ? en : (te.isNotEmpty ? te : hi));
  }

  factory SavedVerse.fromRow(Map<String, Object?> r) => SavedVerse(
        id: (r['id'] as int?) ?? 0,
        kind: (r['kind'] as String?) ?? '',
        bookId: (r['book_id'] as int?) ?? 0,
        chapter: (r['chapter'] as int?) ?? 0,
        verse: (r['verse'] as int?) ?? 0,
        en: (r['text_en'] as String?) ?? '',
        te: (r['text_te'] as String?) ?? '',
        hi: (r['text_hi'] as String?) ?? '',
        createdMs: (r['created_ms'] as int?) ?? 0,
      );
}

/// One chapter read on one day.
class ReadingEntry {
  const ReadingEntry({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.when,
  });

  final int bookId;
  final int chapter;

  /// The verse the reader landed on in that chapter, 0 for the whole chapter.
  final int verse;
  final DateTime when;
}

/// Small SQLite store for everything the believer builds up while studying:
/// settings, bookmarks, favourites and the reading log. (The scripture itself
/// lives in the separate read-only Bible engine, sermons in their own file.)
class StudyDbService {
  StudyDbService._();

  static final StudyDbService instance = StudyDbService._();

  static const String kBookmark = 'bookmark';
  static const String kFavorite = 'favorite';

  static const int _maxLogRows = 500;

  Database? _db;
  Future<Database>? _opening;

  /// One shared open: concurrent first callers wait for the same Future
  /// instead of racing to create the file.
  Future<Database> _open() {
    final Database? existing = _db;
    if (existing != null && existing.isOpen) return Future<Database>.value(existing);
    return _opening ??= _doOpen().whenComplete(() => _opening = null);
  }

  Future<Database> _doOpen() async {
    final String dir = await getDatabasesPath();
    final Database db = await openDatabase(
      join(dir, 'study.db'),
      version: 1,
      onCreate: (Database d, int v) async {
        await d.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        await d.execute('''
CREATE TABLE saved_verses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kind TEXT NOT NULL,
  book_id INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  text_en TEXT,
  text_te TEXT,
  text_hi TEXT,
  created_ms INTEGER NOT NULL,
  UNIQUE (kind, book_id, chapter, verse)
)''');
        await d.execute('''
CREATE TABLE reading_log (
  day TEXT NOT NULL,
  book_id INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL DEFAULT 0,
  last_ms INTEGER NOT NULL,
  PRIMARY KEY (day, book_id, chapter)
)''');
        await d.execute('CREATE INDEX idx_log_last ON reading_log(last_ms)');
      },
    );
    return _db = db;
  }

  // ------------------------------------------------------------ settings

  Future<String?> getSetting(String key) async {
    final Database db = await _open();
    final List<Map<String, Object?>> rows = await db.query('settings',
        columns: <String>['value'],
        where: 'key = ?',
        whereArgs: <Object>[key],
        limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  /// Best effort: a failed settings write must never disturb reading.
  Future<void> setSetting(String key, String value) async {
    try {
      final Database db = await _open();
      await db.insert('settings', <String, Object>{'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  // ------------------------------------------------------- saved verses

  static String keyOf(int bookId, int chapter, int verse) =>
      '$bookId:$chapter:$verse';

  Future<Set<String>> savedKeys(String kind) async {
    final Database db = await _open();
    final List<Map<String, Object?>> rows = await db.query('saved_verses',
        columns: <String>['book_id', 'chapter', 'verse'],
        where: 'kind = ?',
        whereArgs: <Object>[kind]);
    return <String>{
      for (final Map<String, Object?> r in rows)
        keyOf(r['book_id'] as int, r['chapter'] as int, r['verse'] as int),
    };
  }

  Future<void> addSaved(
    String kind, {
    required int bookId,
    required int chapter,
    required int verse,
    required String en,
    required String te,
    required String hi,
  }) async {
    final Database db = await _open();
    await db.insert(
      'saved_verses',
      <String, Object>{
        'kind': kind,
        'book_id': bookId,
        'chapter': chapter,
        'verse': verse,
        'text_en': en,
        'text_te': te,
        'text_hi': hi,
        'created_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeSaved(
    String kind, {
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    final Database db = await _open();
    await db.delete('saved_verses',
        where: 'kind = ? AND book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: <Object>[kind, bookId, chapter, verse]);
  }

  Future<List<SavedVerse>> listSaved(String kind) async {
    final Database db = await _open();
    final List<Map<String, Object?>> rows = await db.query('saved_verses',
        where: 'kind = ?',
        whereArgs: <Object>[kind],
        orderBy: 'created_ms DESC, id DESC');
    return rows.map(SavedVerse.fromRow).toList();
  }

  // ------------------------------------------------------ reading history

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Records that [chapter] of [bookId] was read now (one row per chapter per
  /// day, refreshed to the latest time). Never throws.
  Future<void> logRead(int bookId, int chapter, int verse) async {
    try {
      final Database db = await _open();
      final DateTime now = DateTime.now();
      final String day = _dayKey(now);
      await db.transaction((Transaction txn) async {
        final int changed = await txn.update(
          'reading_log',
          <String, Object>{
            'last_ms': now.millisecondsSinceEpoch,
            if (verse > 0) 'verse': verse,
          },
          where: 'day = ? AND book_id = ? AND chapter = ?',
          whereArgs: <Object>[day, bookId, chapter],
        );
        if (changed == 0) {
          await txn.insert('reading_log', <String, Object>{
            'day': day,
            'book_id': bookId,
            'chapter': chapter,
            'verse': verse,
            'last_ms': now.millisecondsSinceEpoch,
          });
        }
        await txn.rawDelete(
            'DELETE FROM reading_log WHERE rowid NOT IN '
            '(SELECT rowid FROM reading_log ORDER BY last_ms DESC LIMIT $_maxLogRows)');
      });
    } catch (_) {}
  }

  Future<List<ReadingEntry>> history({int limit = 300}) async {
    final Database db = await _open();
    final List<Map<String, Object?>> rows = await db.query('reading_log',
        orderBy: 'last_ms DESC', limit: limit);
    return <ReadingEntry>[
      for (final Map<String, Object?> r in rows)
        ReadingEntry(
          bookId: r['book_id'] as int,
          chapter: r['chapter'] as int,
          verse: (r['verse'] as int?) ?? 0,
          when: DateTime.fromMillisecondsSinceEpoch(r['last_ms'] as int),
        ),
    ];
  }

  Future<void> clearHistory() async {
    final Database db = await _open();
    await db.delete('reading_log');
  }
}

/// In-memory mirror of the bookmark / favourite sets, so a verse card can show
/// its state synchronously and toggle instantly; SQLite is written behind it.
class StudyStore {
  StudyStore._();

  static final StudyStore instance = StudyStore._();

  /// Bumped whenever a set changes; verse cards listen to it.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final Set<String> _bookmarks = <String>{};
  final Set<String> _favorites = <String>{};
  bool _loaded = false;

  Set<String> _setFor(String kind) =>
      kind == StudyDbService.kBookmark ? _bookmarks : _favorites;

  Future<void> load() async {
    if (_loaded) return;
    try {
      _bookmarks
        ..clear()
        ..addAll(await StudyDbService.instance.savedKeys(StudyDbService.kBookmark));
      _favorites
        ..clear()
        ..addAll(await StudyDbService.instance.savedKeys(StudyDbService.kFavorite));
      _loaded = true;
      revision.value++;
    } catch (_) {
      // Retried on the next toggle / next launch.
    }
  }

  bool isSaved(String kind, int bookId, int chapter, int verse) =>
      _setFor(kind).contains(StudyDbService.keyOf(bookId, chapter, verse));

  /// Flips the state at once and persists it. Returns the new state.
  Future<bool> toggle(
    String kind, {
    required int bookId,
    required int chapter,
    required int verse,
    required String en,
    required String te,
    required String hi,
  }) async {
    final String key = StudyDbService.keyOf(bookId, chapter, verse);
    final Set<String> set = _setFor(kind);
    final bool nowSaved = !set.contains(key);
    if (nowSaved) {
      set.add(key);
    } else {
      set.remove(key);
    }
    revision.value++;
    try {
      if (nowSaved) {
        await StudyDbService.instance.addSaved(kind,
            bookId: bookId, chapter: chapter, verse: verse, en: en, te: te, hi: hi);
      } else {
        await StudyDbService.instance
            .removeSaved(kind, bookId: bookId, chapter: chapter, verse: verse);
      }
    } catch (_) {
      // Roll the visible state back so it never lies about what is stored.
      if (nowSaved) {
        set.remove(key);
      } else {
        set.add(key);
      }
      revision.value++;
      return !nowSaved;
    }
    return nowSaved;
  }

  /// Called by the saved-verses screen after it deletes a row itself.
  void forget(String kind, int bookId, int chapter, int verse) {
    _setFor(kind).remove(StudyDbService.keyOf(bookId, chapter, verse));
    revision.value++;
  }

  /// Undo of [forget] when the database delete failed.
  void remember(String kind, int bookId, int chapter, int verse) {
    _setFor(kind).add(StudyDbService.keyOf(bookId, chapter, verse));
    revision.value++;
  }
}
