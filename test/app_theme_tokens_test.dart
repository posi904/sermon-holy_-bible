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
// deliberately animation-free (instant, flicker-free) tab switch.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scripture_sermon_studio/core/l10n.dart';

import 'package:scripture_sermon_studio/core/theme/app_theme.dart';
import 'package:scripture_sermon_studio/core/reader_session.dart';
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

    testWidgets('the bottom bar switches instantly, with no flicker sources',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ScriptureSermonStudioApp());
      await tester.pump(const Duration(milliseconds: 100));

      // The dock paints NO implicit animation at all. An `AnimatedSwitcher`
      // used to key the icon+label on `selected`, keeping the outgoing AND the
      // incoming label alive together so they cross-faded (the blink); an
      // `AnimatedContainer` lerped the wash through a muddy half-alpha grey.
      // Neither may return.
      expect(find.byType(AnimatedSwitcher), findsNothing);
      expect(find.byType(AnimatedContainer), findsNothing);

      // The tab wash declares NO BoxShadow, so no blur can ever be painted.
      expect(_pillOf(tester, AppText.of('te').navReader).boxShadow, isEmpty);

      // The shell boots on the Bible Reader tab...
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        0,
      );

      // ...and a real tap on the Sermon Notes tab swaps the shell on the VERY
      // FIRST frame — no settle/animation frames are needed, which is what
      // "instant" means here.
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        1,
      );
    });

    testWidgets('the tab switch is a single-frame hard swap, never a crossfade',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ScriptureSermonStudioApp());
      await tester.pump(const Duration(milliseconds: 100));

      Color? washOf(String label) =>
          _pillOf(tester, label).color;

      final String reader = AppText.of('te').navReader; // బైబిల్ పఠనం
      final String notes = AppText.of('te').navNotes; // ప్రసంగ నోట్స్
      final Color? activeWash = washOf(reader);

      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      // Exactly one pump: if anything were animating, the two tabs would still
      // be mid-interpolation here.
      await tester.pump();

      // Each frame paints ONE resting + ONE active tab. No frame in between.
      expect(washOf(notes), activeWash);
      expect(washOf(reader), Colors.transparent);
      expect(find.text(reader), findsOneWidget);
      expect(find.text(notes), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each tab keeps its state across a switch (IndexedStack)',
        (WidgetTester tester) async {
      ReaderSession.instance.language.value = 'en';
      await tester.pumpWidget(const ScriptureSermonStudioApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Type a sermon title, leave, and come back: the note must still be there,
      // proving the screen was never rebuilt or torn down.
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
        find.byType(TextField).first,
        'Amen',
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Amen'), findsOneWidget);
      expect(tester.takeException(), isNull);
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

/// The dock's own [Container] — the only one painted the canvas-matched
/// sandalwood face (#FAF2E6). Doubles as the anchor for scoping nav-bar taps.
Finder _dockFinder() => find.byWidgetPredicate(
      (Widget w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == const Color(0xFFFAF2E6),
    );

/// The label [Text] of the nav tab named [label], scoped to the dock so it
/// never collides with an identically-named control inside a screen.
Finder _tabLabel(String label) =>
    find.descendant(of: _dockFinder(), matching: find.text(label));

/// The amber wash [BoxDecoration] currently painted by the nav pill that holds
/// [label]. Ancestors come back innermost-first, so the pill is the FIRST hit
/// (the dock itself is a further ancestor).
BoxDecoration _pillOf(WidgetTester tester, String label) {
  final List<Container> pills = tester
      .widgetList<Container>(
        find.ancestor(
          of: _tabLabel(label),
          matching: find.byType(Container),
        ),
      )
      .toList();
  expect(pills, isNotEmpty, reason: 'the "$label" tab must sit in a pill');
  return pills.first.decoration! as BoxDecoration;
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
