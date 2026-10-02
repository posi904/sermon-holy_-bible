# Scripture & Sermon Studio — UI/UX Dummy Widgets

Standalone Flutter front-end for the 3-screen approved mockup:

1. **Bible Reader** — book/chapter selector, Parallel View / Telugu / English
   toggle, A-/A+ font scaling, synchronized Telugu + English verses.
2. **Sermon Notes** — metadata tags, formatting toolbar, multiline notes
   editor, tappable scripture chips (`[John 3:16]`, `[రోమీయులకు 8:28]`) that
   open a verse-preview bottom sheet with an audio icon.
3. **Prayer Journal / PDF Export** — A4 church-letterhead preview card,
   Bible-reading streak tracker, and a prayer request list.

This package is **UI only**: all content is static, in-memory mock data
(see `lib/core/mock_data.dart`). There is no database, no native platform
code, and no network calls — it uses pure Flutter SDK widgets plus
`cupertino_icons`.

## Milestone 1 — reliable navigation & localized Sermon Notes

This build hardens the two core flows. No new packages were added.

**Verse landing (Bible Reader)**
- The chapter is laid out in one scroll view instead of a lazy list, so every
  verse has a live position and `Scrollable.ensureVisible` lands on it exactly
  (no height estimates, no retry jumps). A chapter is only text (max 176
  verses), so this is cheap on 2 GB phones.
- Each landing request carries a token; rapid picks never fight each other.
- The chosen verse (or range) keeps a persistent soft highlight, tied to the
  chapter it was chosen in, until another passage is chosen.
- Mis-tap recovery: the header's verse button reopens the verse grid of the
  current chapter in one tap, and Android back re-opens it after a pick.

**Sermon Notes**
- `lib/core/reader_session.dart` is the small shared channel between the
  reader, the notes and the shell (reading language, passage jumps, tab
  requests).
- Interface text follows the reader's primary language (`lib/core/l10n.dart`:
  Telugu / English / Hindi).
- References are stored structured (book, chapter, verses) and old plain-text
  ones are upgraded on read. Tapping one opens that exact verse in the reader;
  Android back then returns to the note.
- Saving is silent (700 ms debounce, on pause, on leave, quiet retries); the
  saved list is a chronological log grouped by month.

Not yet built in this milestone: functional Bookmarks / Favorites / Reading
History / Share / Rate / reading themes (the Settings rows still say "coming
soon").

## Milestone 2 — low-RAM fixes, notes polish, study toolkit

**Budget-phone fixes**
- The verse grid in the quick picker no longer touches the database. Verse
  counts come from a built-in table (`lib/core/verse_counts.dart`, generated
  from the bundled Bible), so the grid is painted instantly and can never be
  blank. It also opens clean: the chapter tile you just tapped is no longer
  carried over as a "selected" verse.
- `BibleDbService` opens through ONE shared Future (concurrent first calls used
  to race to install the 28 MB file), forgets a failed open so the next call
  retries, and runs SQLite's full integrity check once after install instead
  of on every launch.
- Verse landing waits until the Bible tab is visible and the verse is really
  laid out, jumps (no animation) into a freshly loaded chapter, then re-checks
  its position three times to correct late layout shifts. Scrolling by hand
  cancels it. Sermon-note deep links use this same path.

**Sermon Notes**: instruction card removed; labelled "Point" / "Verse" buttons
in the capture bar and a separate "Save" button in the header; deleting a saved
sermon updates the sheet and the notepad immediately; the reference sheet shows
"(1 – N)" limits for chapter and verse, refuses impossible numbers and keeps
"Add" disabled until valid.

**Study toolkit** (all in SQLite, `study.db`): bookmarks and favourites (verse
card icons; saved lists open the reader on the exact verse), reading history
(a chapter counts as read after 4 s; grouped by day), four reading themes
(Warm Parchment, Soft Sage, Paper Cream, Midnight Charcoal) applied app-wide
and remembered, font size remembered, native share sheet and Play Store rating
through a small MethodChannel (no plugin).

**Reading themes** work by writing every colour once in its parchment value and
looking it up per theme (`Palette.c`, tables in `palette_tables.dart`). Because
colours are looked up at build time, most widgets are no longer `const`, so the
two `prefer_const_*` style lints are switched off in `analysis_options.yaml`.

**Publishing**: the application ID is `com.posibabu.holybible` — set in
`android/app/build.gradle.kts` (both `namespace` and `applicationId`) and
mirrored by `PlatformService.storeId` in `lib/core/services/platform_service.dart`.
The launcher label `Holy Bible` is set in `android/app/src/main/AndroidManifest.xml`.

## Project structure

```
scripture_sermon_studio/
├── pubspec.yaml
├── analysis_options.yaml
└── lib/
    ├── main.dart                              # App entry + bottom nav bar
    ├── core/
    │   ├── mock_data.dart                     # In-memory mock models & content
    │   └── theme/
    │       └── app_theme.dart                 # Colors, ThemeData, text styles
    └── screens/
        ├── dummy_bible_reader_screen.dart     # Screen 1
        ├── dummy_sermon_notes_screen.dart     # Screen 2
        └── dummy_pdf_journal_screen.dart      # Screen 3
```

## Getting started

This ZIP ships the Dart/Flutter source only (no `android/`, `ios/`, `web/`
platform folders — those are large, machine-generated, and best created
fresh on your machine). After extracting:

```bash
cd scripture_sermon_studio

# 1. Generate platform runner folders for your target(s):
flutter create .

# 2. Fetch dependencies:
flutter pub get

# 3. Run on any connected device/emulator or Chrome:
flutter run
```

`flutter create .` is non-destructive — it only adds the missing
`android/`, `ios/`, `web/`, etc. folders around the existing `lib/` and
`pubspec.yaml`; none of the Dart source you unzipped is touched.

## Notes for wiring up real data later

- Swap the static lists/maps in `lib/core/mock_data.dart` for your actual
  Bible/sermon/prayer data sources (API, SQLite, Isar, etc.) — the screens
  already consume typed models (`VerseModel`, `SermonNoteModel`,
  `PrayerRequest`, …) so the widget code shouldn't need to change much.
- `DummyBibleReaderScreen`, `DummySermonNotesScreen`, and
  `DummyPdfJournalScreen` are fully self-contained `StatefulWidget`s and can
  be dropped into a different navigation shell if needed.
- Telugu text uses standard Unicode (Telugu script, U+0C00–U+0C7F range) and
  renders with the platform's default system font — no custom font asset is
  required, though you can drop a Noto Serif Telugu font into `pubspec.yaml`
  for pixel-perfect typography matching the mockup.
