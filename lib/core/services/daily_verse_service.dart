import 'bible_db_service.dart';

/// One verse of the day, with its text in all three reader languages.
class DailyVerse {
  final int bookId;
  final int chapter;
  final int verse;
  final String en;
  final String te;
  final String hi;
  final int motifIndex; // 1-based, matches assets/motifs/motif_<n>.webp

  const DailyVerse({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.en,
    required this.te,
    required this.hi,
    required this.motifIndex,
  });

  String textFor(String lang) {
    switch (lang) {
      case 'te':
        return te.isNotEmpty ? te : en;
      case 'hi':
        return hi.isNotEmpty ? hi : en;
      default:
        return en;
    }
  }
}

/// Picks and loads the verse of the day.
///
/// Selection is a pure function of the calendar date (local time), so every
/// launch on the same day — and any future background/notification worker —
/// resolves to the exact same verse with no stored state.
class DailyVerseService {
  DailyVerseService._();

  static const int motifCount = 11;

  /// Curated encouragement / core passages as (bookId, chapter, verse), using
  /// canonical book numbering (1 = Genesis … 66 = Revelation).
  static const List<List<int>> curated = [
    [43, 3, 16], [19, 23, 1], [45, 8, 28], [50, 4, 13], [24, 29, 11],
    [23, 41, 10], [20, 3, 5], [40, 11, 28], [6, 1, 9], [19, 46, 1],
    [19, 119, 105], [23, 40, 31], [45, 12, 2], [48, 2, 20], [49, 2, 8],
    [58, 11, 1], [47, 5, 17], [40, 6, 33], [43, 14, 6], [43, 14, 27],
    [19, 27, 1], [19, 91, 1], [25, 3, 22], [33, 6, 8], [60, 5, 7],
    [59, 1, 5], [62, 4, 19], [66, 21, 4], [5, 31, 6], [19, 34, 8],
    [19, 37, 4], [20, 16, 3], [23, 26, 3], [40, 5, 16], [45, 5, 8],
    [46, 13, 13], [51, 3, 23], [52, 5, 16], [58, 13, 8], [55, 1, 7],
  ];

  /// Index into [curated] for [date]. Pure and deterministic.
  static int indexFor(DateTime date) {
    final int day =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    return day % curated.length;
  }

  /// Loads today's verse. If a row is missing or empty (should not happen with
  /// the bundled database) the next curated entry is tried, so the card never
  /// shows an empty verse. Returns null only if the database is unavailable.
  static Future<DailyVerse?> load([DateTime? date]) async {
    final DateTime d = date ?? DateTime.now();
    final int start = indexFor(d);
    final int motif = (start % motifCount) + 1;
    for (int i = 0; i < curated.length; i++) {
      final List<int> ref = curated[(start + i) % curated.length];
      try {
        final rows = await BibleDbService.instance.getVerses(
          bookId: ref[0],
          chapter: ref[1],
        );
        for (final row in rows) {
          if (row['verse'] == ref[2]) {
            final String en = ((row['en'] as String?) ?? '').trim();
            if (en.isEmpty) break;
            return DailyVerse(
              bookId: ref[0],
              chapter: ref[1],
              verse: ref[2],
              en: en,
              te: ((row['te'] as String?) ?? '').trim(),
              hi: ((row['hi'] as String?) ?? '').trim(),
              motifIndex: motif,
            );
          }
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
