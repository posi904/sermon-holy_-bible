// Smoke tests for the Scripture & Sermon Studio shell and the two screens that
// received the unified Golden Amber design treatment.
//
// The shell tests drive the floating bottom navigation bar; the per-screen
// tests render each screen on its own inside a very tall viewport so that every
// lazily-built list row is materialised and can be asserted on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scripture_sermon_studio/core/l10n.dart';
import 'package:scripture_sermon_studio/core/reader_session.dart';
import 'package:scripture_sermon_studio/core/theme/app_theme.dart';
import 'package:scripture_sermon_studio/main.dart';
import 'package:scripture_sermon_studio/screens/dummy_pdf_journal_screen.dart';
import 'package:scripture_sermon_studio/screens/dummy_sermon_notes_screen.dart';

/// Boots [screen] on its own with the app theme inside a very tall viewport.
Future<void> _pumpTallScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1200, 7000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('Floating bottom bar exposes both destinations, localised',
      (WidgetTester tester) async {
    ReaderSession.instance.language.value = 'te';
    await tester.pumpWidget(const ScriptureSermonStudioApp());
    await tester.pump(const Duration(milliseconds: 100));

    final AppText te = AppText.of('te');
    expect(find.text(te.navReader), findsOneWidget);
    expect(find.text(te.navNotes), findsOneWidget);
  });

  testWidgets('Tapping a destination swaps the active screen',
      (WidgetTester tester) async {
    ReaderSession.instance.language.value = 'te';
    await tester.pumpWidget(const ScriptureSermonStudioApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text(AppText.of('te').navNotes));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      1,
    );
  });

  testWidgets('A scripture-reference jump brings the Bible Reader forward',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScriptureSermonStudioApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text(AppText.of('te').navNotes));
    await tester.pump(const Duration(milliseconds: 300));

    ReaderSession.instance.openPassage(
      ScriptureJump(bookId: 45, chapter: 8, verseStart: 28, fromNotes: true),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      0,
    );
  });

  testWidgets('Prayer Journal leads with a golden amber Share PDF action',
      (WidgetTester tester) async {
    await _pumpTallScreen(tester, const DummyPdfJournalScreen());

    // Share replaces the old rigid Print action; Export keeps the outline style.
    expect(find.text('Share PDF'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Print'), findsNothing);

    // Streak card and the individual prayer cards are all present.
    expect(find.text('7 Day Streak'), findsOneWidget);
    expect(find.text('Healing for Mom'), findsOneWidget);
    expect(find.text('Wisdom for job decision'), findsOneWidget);

    // Answered / Waiting badges are rendered.
    expect(find.text('Answered'), findsWidgets);
    expect(find.text('Waiting'), findsWidgets);
  });

  testWidgets('Sermon Notes offers quick service chips and capture fields',
      (WidgetTester tester) async {
    ReaderSession.instance.language.value = 'en';
    await _pumpTallScreen(tester, const DummySermonNotesScreen());

    expect(find.text('Sunday Service'), findsOneWidget);
    expect(find.text('Fasting Prayer'), findsOneWidget);
    expect(find.text('Youth Fellowship'), findsOneWidget);
    expect(find.text('Mid-week Service'), findsOneWidget);
    expect(find.text('Other\u2026'), findsOneWidget);
    expect(find.text('Preacher / Pastor name'), findsOneWidget);
    expect(find.text('Add a sermon point\u2026'), findsOneWidget);
  });

  testWidgets('Sermon Notes follows the reader language live',
      (WidgetTester tester) async {
    ReaderSession.instance.language.value = 'en';
    await _pumpTallScreen(tester, const DummySermonNotesScreen());
    expect(find.text('Sermon Notes'), findsOneWidget);

    ReaderSession.instance.language.value = 'te';
    await tester.pump(const Duration(milliseconds: 100));
    final AppText te = AppText.of('te');
    expect(find.text(te.notesTitle), findsOneWidget);
    expect(find.text(te.preacherHint), findsOneWidget);
    expect(find.text(te.serviceLabel('Sunday Service')), findsOneWidget);

    ReaderSession.instance.language.value = 'hi';
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(AppText.of('hi').notesTitle), findsOneWidget);
  });
}
