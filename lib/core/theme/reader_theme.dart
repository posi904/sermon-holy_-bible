import 'dart:async';

import 'package:flutter/material.dart';

import '../services/study_db_service.dart';
import 'palette_tables.dart';

/// The reading themes. All are low-glare: no pure white anywhere, no
/// saturated solids, and every text/background pair clears WCAG AA (most AAA).
enum ReaderThemeId { parchment, sage, cream, midnight }

class ReaderThemeSpec {
  const ReaderThemeSpec({
    required this.id,
    required this.brightness,
    required this.table,
  });

  final ReaderThemeId id;
  final Brightness brightness;

  /// Original warm-parchment colour -> this theme's colour.
  final Map<int, int> table;
}

const List<ReaderThemeSpec> kReaderThemes = <ReaderThemeSpec>[
  ReaderThemeSpec(
      id: ReaderThemeId.parchment,
      brightness: Brightness.light,
      table: kTableParchment),
  ReaderThemeSpec(
      id: ReaderThemeId.sage,
      brightness: Brightness.light,
      table: kTableSage),
  ReaderThemeSpec(
      id: ReaderThemeId.cream,
      brightness: Brightness.light,
      table: kTableCream),
  ReaderThemeSpec(
      id: ReaderThemeId.midnight,
      brightness: Brightness.dark,
      table: kTableMidnight),
];

ReaderThemeSpec specFor(ReaderThemeId id) =>
    kReaderThemes.firstWhere((ReaderThemeSpec s) => s.id == id);

/// Colour lookup for the active reading theme.
///
/// The UI is written once in warm-parchment colours; `Palette.c(0xFF...)`
/// returns the same role in whichever theme is active. Results are memoised,
/// so a lookup in `build` is a single hash probe (no allocation after the
/// first use).
class Palette {
  Palette._();

  static ReaderThemeSpec _spec = kReaderThemes.first;
  static Map<int, Color> _cache = <int, Color>{};

  static ReaderThemeId get id => _spec.id;
  static Brightness get brightness => _spec.brightness;

  static void use(ReaderThemeId next) {
    _spec = specFor(next);
    _cache = <int, Color>{};
  }

  static Color c(int argb) {
    final Color? hit = _cache[argb];
    if (hit != null) return hit;
    return _cache[argb] = Color(_spec.table[argb] ?? argb);
  }
}

/// Holds the chosen theme, persists it (SQLite) and notifies the app shell.
class ReaderThemeController {
  ReaderThemeController._();

  static final ReaderThemeController instance = ReaderThemeController._();

  final ValueNotifier<ReaderThemeId> id =
      ValueNotifier<ReaderThemeId>(ReaderThemeId.parchment);

  /// Reads the saved theme. Never throws and never blocks start-up for long.
  Future<void> load() async {
    try {
      final String? saved = await StudyDbService.instance
          .getSetting('theme')
          .timeout(const Duration(milliseconds: 900));
      if (saved == null) return;
      for (final ReaderThemeId t in ReaderThemeId.values) {
        if (t.name == saved) {
          Palette.use(t);
          id.value = t;
          return;
        }
      }
    } catch (_) {
      // First launch, or a slow device: parchment is a fine default.
    }
  }

  void select(ReaderThemeId next) {
    if (next == id.value) return;
    Palette.use(next);
    id.value = next;
    unawaited(StudyDbService.instance.setSetting('theme', next.name));
  }
}
