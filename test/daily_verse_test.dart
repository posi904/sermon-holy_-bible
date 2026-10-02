import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_sermon_studio/core/services/daily_verse_service.dart';

void main() {
  test('same date always yields the same verse index', () {
    final a = DailyVerseService.indexFor(DateTime(2026, 9, 30, 6));
    final b = DailyVerseService.indexFor(DateTime(2026, 9, 30, 23, 59));
    expect(a, b);
  });

  test('consecutive days rotate through the curated list', () {
    final n = DailyVerseService.curated.length;
    final today = DailyVerseService.indexFor(DateTime(2026, 9, 30));
    final tomorrow = DailyVerseService.indexFor(DateTime(2026, 10, 1));
    expect(tomorrow, (today + 1) % n);
  });

  test('every curated reference uses a valid book id', () {
    for (final r in DailyVerseService.curated) {
      expect(r[0], inInclusiveRange(1, 66));
      expect(r[1], greaterThan(0));
      expect(r[2], greaterThan(0));
    }
  });
}
