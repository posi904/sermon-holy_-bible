// Tests for the centralized semantic colour-token system that backs the Bible
// Reader's language / control identities.
//
// Task scope is visual only, so these tests guard the *tokens* rather than the
// pixels: each identity must live in its approved colour family, every
// selected fill must stay readable with white content, and every control must
// expose a deterministic selected-vs-surface pair. Widget smoke checks also
// prove the reader still renders all four controls at a compact phone width
// without overflow.
//
// The final group guards the paper recipes — the ReaderPalette study-bible card
// (#F6EFDF) under its #DCCBA8 hairline (r15 reading cards) and the warm
// parchment book-picker rows (r12 gradient tiles with the shared micro-lift
// shadow) — plus the 2-tab bottom bar's permanently shadow-free dock and its
// 150ms fade/slide tab switch.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scripture_sermon_studio/core/l10n.dart';

import 'package:scripture_sermon_studio/core/theme/app_theme.dart';
import 'package:scripture_sermon_studio/main.dart';
import 'package:scripture_sermon_studio/screens/dummy_bible_reader_screen.dart';

/// WCAG relative luminance of [c] (0 = black, 1 = white).
double _luminance(Color c) {
  double linear(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
}

/// WCAG contrast ratio between two opaque colours (1 = none, 21 = maximum).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// The four approved language identities, paired with a human label.
const Map<String, ({Color surface, Color selected, Color border})> _identities = {
  'English': (
    surface: AppColors.languageEnglishSurface,
    selected: AppColors.languageEnglishSelected,
    border: AppColors.languageEnglishBorder,
  ),
  'Telugu': (
    surface: AppColors.languageTeluguSurface,
    selected: AppColors.languageTeluguSelected,
    border: AppColors.languageTeluguBorder,
  ),
  'Hindi': (
    surface: AppColors.languageHindiSurface,
    selected: AppColors.languageHindiSelected,
    border: AppColors.languageHindiBorder,
  ),
  'Parallel': (
    surface: AppColors.languageParallelSurface,
    selected: AppColors.languageParallelSelected,
    border: AppColors.languageParallelBorder,
  ),
};

void main() {
  group('Semantic token identities', () {
    test('English is the warm amber / golden brand family', () {
      const c = AppColors.languageEnglishSelected;
      expect(c.r, greaterThan(c.g));
      expect(c.g, greaterThan(c.b));
    });

    test('Telugu is the professional green family', () {
      const c = AppColors.languageTeluguSelected;
      expect(c.g, greaterThan(c.r));
      expect(c.g, greaterThan(c.b));
    });

    test('Hindi is the professional pink / rose family', () {
      const c = AppColors.languageHindiSelected;
      // Rose = red + blue over green.
      expect(c.r, greaterThan(c.g));
      expect(c.b, greaterThan(c.g));
    });

    test('Parallel is the professional blue family', () {
      const c = AppColors.languageParallelSelected;
      expect(c.b, greaterThan(c.g));
      expect(c.b, greaterThan(c.r));
    });

    test('the four selected identities are mutually distinct', () {
      final selected = _identities.values.map((e) => e.selected).toList();
      expect(selected.toSet().length, selected.length);
    });
  });

  group('Selected vs unselected are deterministic', () {
    for (final entry in _identities.entries) {
      test('${entry.key} selected fill is solid, dark and readable', () {
        final id = entry.value;
        // Solid/opaque (no accidental transparency).
        expect(id.selected.a, 1.0);
        // Selected must not read the same as the resting tint or its hairline.
        expect(id.selected, isNot(id.surface));
        expect(id.selected, isNot(id.border));
        // White content on the selected fill clears WCAG AA (4.5:1).
        expect(_contrast(id.selected, AppColors.iconOnAccent),
            greaterThanOrEqualTo(4.5));
      });

      test('${entry.key} resting surface is a quiet light tint', () {
        final id = entry.value;
        expect(id.surface.a, 1.0);
        expect(_luminance(id.surface), greaterThan(0.7));
        // Deep espresso text stays comfortably readable on the light tint.
        expect(_contrast(id.surface, AppColors.textPrimary),
            greaterThanOrEqualTo(4.5));
        // The tint is genuinely tinted, not a flat white / near-white.
        expect(id.surface, isNot(AppColors.iconOnAccent));
      });
    }
  });

  group('Reader controls', () {
    testWidgets('expose English, Telugu, Hindi and Parallel on one row',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DummyBibleReaderScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('English'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('TE | EN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switch selected language and Parallel mode without overflow',
        (WidgetTester tester) async {
      // Logical 360x640 compact phone viewport.
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DummyBibleReaderScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // The reader boots in Parallel mode; each single-language tap must switch
      // the active identity cleanly, and tapping the in-pill pair label must
      // toggle Parallel mode back on without overflow.
      for (final label in const ['English', 'తెలుగు', 'हिन्दी', 'TE | EN']) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull,
            reason: 'tapping "$label" must not overflow or throw');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Paper recipes (ReaderPalette study paper) + snappy 2-tab bottom bar switch
  // ---------------------------------------------------------------------------
  // The verse cards read on the ReaderPalette study-bible card (#F6EFDF) under
  // its shared #DCCBA8 hairline at r15, while the book-picker rows keep their
  // warm parchment r12 gradient tiles; and a tab switch is a shadow-free 150ms
  // fade/slide with no dock band.

  group('Paper recipes (ReaderPalette study paper) + snappy 2-tab bottom bar',
      () {
    test('the reading face is the ReaderPalette study-bible paper', () {
      // The reader's paper family: a warm study card on an aged canvas, sealed
      // by one sandalwood hairline.
      expect(ReaderPalette.card, const Color(0xFFF6EFDF));
      expect(ReaderPalette.cardBorder, const Color(0xFFDCCBA8));
      expect(ReaderPalette.canvas, const Color(0xFFEFE6D4));
      // A warm near-white reading face — never a harsh pure white.
      expect(_luminance(ReaderPalette.card), greaterThan(0.85));
      expect(ReaderPalette.card, isNot(AppColors.iconOnAccent));
      // The family is genuinely tiered: face, hairline and canvas all differ.
      expect(ReaderPalette.card, isNot(ReaderPalette.canvas));
      expect(ReaderPalette.cardBorder, isNot(ReaderPalette.card));
      // Deep espresso scripture ink keeps a very high contrast on it (WCAG AAA).
      expect(_contrast(ReaderPalette.card, ReaderPalette.ink),
          greaterThanOrEqualTo(7.0));
    });

    test('the picker keeps its warm linen cream face + sandalwood hairline', () {
      expect(AppColors.warmCream, const Color(0xFFFBF8F2));
      expect(AppColors.warmCreamBorder, const Color(0xFFE8E0D2));
      // Never pure white: the faint sand cast is the whole point.
      expect(AppColors.warmCream, isNot(AppColors.iconOnAccent));
      // Deep espresso scripture ink stays comfortably readable on the cream.
      expect(_contrast(AppColors.warmCream, const Color(0xFF1C140E)),
          greaterThanOrEqualTo(4.5));
      // The hairline draws the card edge without hardening into a dark rule.
      expect(AppColors.warmCreamBorder, isNot(AppColors.warmCream));
      expect(_luminance(AppColors.warmCreamBorder), greaterThan(0.6));
    });

    test('the cream elevation is a soft 1-2dp micro-lift', () {
      final shadow = AppElevation.cream.single;
      expect(shadow.blurRadius, lessThanOrEqualTo(4.0));
      expect(shadow.offset.dy, inInclusiveRange(1.0, 2.0));
      expect(shadow.spreadRadius, 0.0);
      // Deliberately cheaper than the ambient 12px card recipe it replaces.
      expect(shadow.blurRadius, lessThan(AppElevation.card.first.blurRadius));
    });

    testWidgets('the reading stack paints its warm paper panel, never white',
        (WidgetTester tester) async {
      // Logical 360x640 compact phone viewport.
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DummyBibleReaderScreen()),
      );
      await tester.pump(const Duration(milliseconds: 400));

      final List<BoxDecoration> faces = _decorations(tester);

      // Verse rows are streamed from the bundled SQLite engine, which has no
      // platform plugin under `flutter test`, so the panel that is guaranteed
      // to paint here is the reading stack's chapter-nav footer. It wears the
      // same study-paper family the verse cards use (ReaderPalette.card, r15,
      // #DCCBA8 hairline) one notch warmer, at r16 under a #DAC5A3 hairline.
      final List<BoxDecoration> readingPanels = faces
          .where((d) => d.color == const Color(0xFFF6EBD9))
          .toList();
      expect(readingPanels, hasLength(1),
          reason: 'the reading stack must paint its warm paper panel');

      final BoxDecoration panel = readingPanels.single;
      final Border frame = panel.border! as Border;
      expect(frame.top.color, const Color(0xFFDAC5A3));
      expect(frame.top.width, 1.0);
      expect(panel.borderRadius, BorderRadius.circular(16));
      expect(panel.boxShadow, isNotEmpty);

      // Nothing in the stack may fall back to pure white — nor to the retired
      // pale-sage reading tint the reader no longer wears.
      expect(faces.map((d) => d.color), isNot(contains(Colors.white)));
      expect(faces.map((d) => d.color),
          isNot(contains(AppColors.verseCardFace)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('resting book tiles are raised parchment rows',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const DummyBibleReaderScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // The selector pill's trailing chevron is the one door into the picker.
      await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded));
      await tester.pumpAndSettle();

      // The picker's resting rows share the ONE warm parchment pill: an r12
      // gradient tile under the shared #D6C5A9 sandalwood hairline with one
      // cheap micro-lift. Pinning the wash keeps the reader's other r12 rows
      // (the Verse-of-the-Day quick actions) out of the match, so the assertion
      // can only pass when the book list is actually on screen.
      final List<BoxDecoration> restingTiles = _decorations(tester)
          .where((d) =>
              d.borderRadius == BorderRadius.circular(12) &&
              d.border?.top.color == const Color(0xFFD6C5A9) &&
              _isParchmentWash(d.gradient))
          .toList();

      expect(restingTiles, isNotEmpty,
          reason: 'resting book rows must be raised parchment tiles');
      for (final tile in restingTiles) {
        expect(tile.boxShadow, isNotEmpty);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the bottom bar switches with one 150ms shadow-free fade/slide',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ScriptureSermonStudioApp());
      await tester.pump(const Duration(milliseconds: 100));

      // The 2-tab dock (Bible Reader / Sermon Notes) crossfades each tab
      // through the shared 150ms switch.
      final List<AnimatedSwitcher> switchers = tester
          .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))
          .where((s) => s.duration == const Duration(milliseconds: 150))
          .toList();
      expect(switchers, isNotEmpty);

      // ...while the tab wash declares NO BoxShadow at all, so no blur can be
      // interpolated frame-by-frame mid-switch.
      final AnimatedContainer wash = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text(AppText.of('te').navReader),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect((wash.decoration! as BoxDecoration).boxShadow, isEmpty);

      // The shell boots on the Bible Reader tab...
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        0,
      );

      // ...and a real tap on the Sermon Notes tab swaps the shell without
      // throwing mid-animation.
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        1,
      );
    });

    testWidgets('the live bottom dock paints no blur or shadow band at all',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ScriptureSermonStudioApp());
      await tester.pump(const Duration(milliseconds: 100));

      // The dock is the ONE [Container] painting the canvas-matched sandalwood
      // face (#FAF2E6) the shell shows behind every screen.
      final List<Container> docks = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) =>
              container.decoration is BoxDecoration &&
              (container.decoration! as BoxDecoration).color ==
                  const Color(0xFFFAF2E6))
          .toList();
      expect(docks, hasLength(1),
          reason: 'the live bottom dock must be that single Container');

      // No BoxShadow of any kind — a shadow-free dock cannot smear a permanent
      // dark blur band over the content above it.
      final BoxDecoration dock = docks.single.decoration! as BoxDecoration;
      expect(dock.boxShadow, isNull);
      // Its elevation reads through the golden top hairline alone.
      final Border seal = dock.border! as Border;
      expect(seal.top.color, const Color(0xFFD8B276).withValues(alpha: 0.5));
      expect(seal.top.width, 1.0);

      // No blur/filter layer may sit behind the bar either.
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Every [BoxDecoration] currently painted by a [Container] in the tree.
List<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((container) => container.decoration)
    .whereType<BoxDecoration>()
    .toList();

/// True when [gradient] is the ONE warm parchment wash (#FFF9ED → #F1E5CF) that
/// the book-picker rows share.
bool _isParchmentWash(Gradient? gradient) =>
    gradient is LinearGradient &&
    gradient.colors.contains(const Color(0xFFFFF9ED));
