import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Read-only access to the bundled SQLite Bible engine
/// (`assets/bible/bible_engine.db`, copied to the app documents directory on
/// first launch).
///
/// Schema (one row per verse, indexed by `idx_book_chapter`):
///
/// ```
/// CREATE TABLE verses (
///   id       INTEGER PRIMARY KEY AUTOINCREMENT,
///   book_id  INTEGER NOT NULL,
///   chapter  INTEGER NOT NULL,
///   verse    INTEGER NOT NULL,
///   en       TEXT,
///   te       TEXT,
///   hi       TEXT
/// );
/// CREATE INDEX idx_book_chapter ON verses(book_id, chapter);
/// ```
class BibleDbService {
  BibleDbService._();

  static final BibleDbService instance = BibleDbService._();

  /// Bundled pre-populated database file name.
  static const String _dbName = 'bible_engine.db';

  static const String _assetKey = 'assets/bible/bible_engine.db';

  Database? _db;
  Future<Database>? _opening;
  bool _verified = false;

  Future<void> _installFromAsset(String dbPath) async {
    final okMarker = File('$dbPath.ok');
    if (okMarker.existsSync()) await okMarker.delete();
    final data = await rootBundle.load(_assetKey);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    // Write to a temp file, then rename: a crash mid-copy can never leave a
    // half-written database at the real path.
    final tmp = File('$dbPath.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    final target = File(dbPath);
    if (target.existsSync()) await target.delete();
    await tmp.rename(dbPath);
    await File('$dbPath.len').writeAsString('${bytes.length}', flush: true);
  }

  /// True when the installed copy is present, matches the length recorded at
  /// install time, and has passed SQLite's own consistency check.
  ///
  /// The (full-file, slow on a budget phone) integrity check runs ONCE after an
  /// install and is remembered in a `.ok` marker; every later launch only
  /// compares the file length, so opening the Bible stays instant.
  Future<bool> _installedCopyIsSound(String dbPath) async {
    final file = File(dbPath);
    final marker = File('$dbPath.len');
    final proven = File('$dbPath.ok');
    if (!file.existsSync() || !marker.existsSync()) return false;
    final expected = int.tryParse((await marker.readAsString()).trim());
    if (expected == null || expected != await file.length()) return false;
    if (proven.existsSync()) return true;
    try {
      final probe = await openDatabase(dbPath, readOnly: true);
      final rows = await probe.rawQuery('PRAGMA quick_check(1)');
      await probe.close();
      final bool ok = rows.isNotEmpty && rows.first.values.first == 'ok';
      if (ok) await proven.writeAsString('ok', flush: true);
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Opens (and caches) the SQLite database. The bundled scripture is
  /// read-only; if the installed copy is missing, truncated, altered in size
  /// or fails an integrity check, it is restored from the app bundle.
  ///
  /// Concurrent callers share ONE open (they used to race, each trying to
  /// install the 28 MB file at once); a failed attempt is forgotten, so the
  /// next call starts clean instead of staying broken.
  Future<Database> _open() {
    final existing = _db;
    if (existing != null && existing.isOpen) return Future<Database>.value(existing);
    return _opening ??= _openOnce().whenComplete(() => _opening = null);
  }

  Future<Database> _openOnce() async {
    try {
      final dir = await getDatabasesPath();
      final dbPath = join(dir, _dbName);

      if (!_verified) {
        if (!await _installedCopyIsSound(dbPath)) {
          await _installFromAsset(dbPath);
        }
        _verified = true;
      }

      return _db = await openDatabase(dbPath, readOnly: true);
    } catch (_) {
      _verified = false;
      rethrow;
    }
  }

  /// All verses of [chapter] in [bookId], ordered by verse number.
  ///
  /// Each row map carries the keys `verse`, `en`, `te`, `hi`.
  ///
  /// Throws when the engine is unavailable (missing asset / platform plugin);
  /// the reader catches and falls back so the UI never breaks.
  Future<List<Map<String, dynamic>>> getVerses({
    required int bookId,
    required int chapter,
  }) async {
    final db = await _open();
    return db.query(
      'verses',
      columns: const ['verse', 'en', 'te', 'hi'],
      where: 'book_id = ? AND chapter = ?',
      whereArgs: <Object>[bookId, chapter],
      orderBy: 'verse ASC',
    );
  }

  /// Closes the cached connection (used by tests / hot restarts).
  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null && db.isOpen) await db.close();
  }
}
