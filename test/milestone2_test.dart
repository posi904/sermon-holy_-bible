// Milestone 2: verse-count table, reading themes, the clean verse grid, and
// the validated scripture-reference sheet.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scripture_sermon_studio/core/l10n.dart';
import 'package:scripture_sermon_studio/core/mock_data.dart';
import 'package:scripture_sermon_studio/core/reader_session.dart';
import 'package:scripture_sermon_studio/core/theme/app_theme.dart';
import 'package:scripture_sermon_studio/core/theme/reader_theme.dart';
import 'package:scripture_sermon_studio/core/verse_counts.dart';
import 'package:scripture_sermon_studio/screens/dummy_bible_reader_screen.dart';
import 'package:scripture_sermon_studio/screens/dummy_sermon_notes_screen.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('verse count table', () {
    test('matches known chapters', () {
      expect(verseCountOf(43, 3), 36); // John 3
      expect(verseCountOf(19, 119), 176); // Psalm 119
      expect(chapterCountOf(63), 1); // 2 John
      expect(verseCountOf(63, 1), 13);
      expect(verseCountOf(41, 8), 38); // Mark 8
    });

    test('covers every chapter the book list promises', () {
      for (int i = 0; i < MockBible.books.length; i++) {
        expect(chapterCountOf(i + 1), MockBible.books[i].chapterCount,
            reason: MockBible.books[i].englishName);
      }
    });

    test('has 31,102 verses in total', () {
      int total = 0;
      for (int b = 1; b <= 66; b++) {
        for (int c = 1; c <= chapterCountOf(b); c++) {
          total += verseCountOf(b, c);
        }
      }
      expect(total, 31102);
    });

    test('unknown references give 0', () {
      expect(verseCountOf(0, 1), 0);
      expect(verseCountOf(67, 1), 0);
      expect(verseCountOf(43, 99), 0);
    });
  });

  group('reading themes', () {
    tearDown(() => Palette.use(ReaderThemeId.parchment));

    test('there are four, each defines the same colours', () {
      expect(kReaderThemes, hasLength(4));
      final Set<int> keys = kReaderThemes.first.table.keys.toSet();
      for (final ReaderThemeSpec s in kReaderThemes) {
        expect(s.table.keys.toSet(), keys, reason: s.id.name);
      }
    });

    test('every theme keeps text readable and glare low', () {
      for (final ReaderThemeSpec s in kReaderThemes) {
        Palette.use(s.id);
        expect(_contrast(ReaderPalette.ink, ReaderPalette.card), greaterThan(7),
            reason: '${s.id.name} ink on card');
        expect(_contrast(ReaderPalette.inkSoft, ReaderPalette.card),
            greaterThan(4.5),
            reason: '${s.id.name} soft ink on card');
        expect(_contrast(ReaderPalette.ink, ReaderPalette.canvas), greaterThan(7),
            reason: '${s.id.name} ink on canvas');
        expect(ReaderPalette.card, isNot(const Color(0xFFFFFFFF)));
        expect(ReaderPalette.ink, isNot(const Color(0xFFFFFFFF)));
        expect(ReaderPalette.card, isNot(ReaderPalette.canvas));
      }
    });

    test('the night theme is genuinely dark, the others genuinely light', () {
      Palette.use(ReaderThemeId.midnight);
      expect(ReaderPalette.card.computeLuminance(), lessThan(0.05));
      expect(ReaderPalette.ink.computeLuminance(), greaterThan(0.5));
      Palette.use(ReaderThemeId.sage);
      expect(ReaderPalette.card.computeLuminance(), greaterThan(0.6));
    });

    test('the highlighted verse stays distinguishable from a resting card', () {
      for (final ReaderThemeSpec s in kReaderThemes) {
        Palette.use(s.id);
        expect(ReaderPalette.pulse, isNot(ReaderPalette.card));
        expect(_contrast(ReaderPalette.pulse, ReaderPalette.card),
            greaterThan(1.1),
            reason: s.id.name);
        expect(_contrast(ReaderPalette.ink, ReaderPalette.pulse), greaterThan(7),
            reason: '${s.id.name} ink on highlight');
      }
    });

    test('the default theme is the original warm parchment', () {
      Palette.use(ReaderThemeId.parchment);
      expect(ReaderPalette.card, const Color(0xFFF6EFDF));
      expect(ReaderPalette.canvas, const Color(0xFFEFE6D4));
    });

    test('ReadingTheme follows the active palette', () {
      Palette.use(ReaderThemeId.midnight);
      final ThemeData dark = ReadingTheme.current;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, ReaderPalette.canvas);
      Palette.use(ReaderThemeId.cream);
      expect(ReadingTheme.current.brightness, Brightness.light);
    });
  });

  group('quick picker', () {
    testWidgets('the verse grid opens clean: nothing is pre-selected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DummyBibleReaderScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded));
      await tester.pumpAndSettle();

      // Pick a book, then chapter 1 (every book has one).
      await tester.tap(find
          .descendant(
              of: find.byType(BottomSheet),
              matching: find.byIcon(Icons.menu_book_rounded))
          .first);
      await tester.pumpAndSettle();
      await tester.tap(find
          .descendant(
              of: find.byType(BottomSheet), matching: find.text('1'))
          .first);
      await tester.pumpAndSettle();

      // Verse step: the grid is painted at once (verse 1 is there) and no
      // tile wears the tapped-gold or the selected-wash fill.
      expect(find.text('1'), findsWidgets);
      final List<Color?> fills = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color)
          .toList();
      expect(fills, isNot(contains(const Color(0xFFC88A2E))));
      expect(fills, isNot(contains(const Color(0xFFF7E6C4))));
      expect(tester.takeException(), isNull);
    });
  });

  group('scripture reference sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      ReaderSession.instance.language.value = 'te';
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
            theme: AppTheme.light, home: const DummySermonNotesScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.menu_book_rounded).last);
      await tester.pumpAndSettle();
    }

    Finder sheetFields() => find.descendant(
        of: find.byType(BottomSheet), matching: find.byType(TextField));

    testWidgets('shows the chapter limit and keeps Add disabled until valid',
        (WidgetTester tester) async {
      await openSheet(tester);
      final AppText t = AppText.of('te');

      // John (default) has 21 chapters.
      expect(find.text(t.rangeHint(21)), findsOneWidget);
      FilledButton button() => tester.widget<FilledButton>(find.descendant(
          of: find.byType(BottomSheet), matching: find.byType(FilledButton)));
      expect(button().onPressed, isNull);

      await tester.enterText(sheetFields().first, '7');
      await tester.pump();
      expect(button().onPressed, isNotNull);
    });

    testWidgets('refuses an impossible chapter such as 899',
        (WidgetTester tester) async {
      await openSheet(tester);
      await tester.enterText(sheetFields().first, '899');
      await tester.pump();

      final TextField field = tester.widget<TextField>(sheetFields().first);
      expect(field.controller!.text, isNot('899'));
      expect(int.tryParse(field.controller!.text) ?? 0, lessThanOrEqualTo(21));
    });
  });
}
