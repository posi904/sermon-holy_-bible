import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/reader_theme.dart';

/// Lets the believer pick one of the reading themes. The choice applies to the
/// whole app at once (the sheet itself repaints too) and is remembered.
class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key, required this.text});

  final AppText text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: ValueListenableBuilder<ReaderThemeId>(
          valueListenable: ReaderThemeController.instance.id,
          builder: (BuildContext context, ReaderThemeId selected, Widget? child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text.themeSheetTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Palette.c(0xFF261D16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text.themeSheetNote,
                  style: TextStyle(fontSize: 12.5, color: ReaderPalette.inkSoft),
                ),
                const SizedBox(height: 14),
                for (final ReaderThemeSpec spec in kReaderThemes)
                  _ThemeOption(
                    spec: spec,
                    text: text,
                    selected: spec.id == selected,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.spec,
    required this.text,
    required this.selected,
  });

  final ReaderThemeSpec spec;
  final AppText text;
  final bool selected;

  /// The colour [original] (a parchment value) takes in THIS theme, so every
  /// option previews itself even while another theme is active.
  Color _in(int original) => Color(spec.table[original] ?? original);

  @override
  Widget build(BuildContext context) {
    final Color canvas = _in(0xFFEFE6D4);
    final Color card = _in(0xFFF6EFDF);
    final Color ink = _in(0xFF2A1F16);
    final Color soft = _in(0xFF6E5B45);
    final Color accent = _in(0xFFB07A2A);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ReaderThemeController.instance.select(spec.id),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ReaderPalette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? ReaderPalette.gold
                    : ReaderPalette.cardBorder,
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Row(
              children: [
                // Mini page preview in the theme's own colours.
                Container(
                  width: 64,
                  height: 52,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: canvas,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 4,
                            width: 30,
                            decoration: BoxDecoration(
                                color: ink,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 4),
                        Container(
                            height: 3,
                            width: 38,
                            decoration: BoxDecoration(
                                color: soft,
                                borderRadius: BorderRadius.circular(2))),
                        const Spacer(),
                        Container(
                            height: 4,
                            width: 12,
                            decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.themeName(spec.id.name),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: Palette.c(0xFF261D16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text.themeNote(spec.id.name),
                        style: TextStyle(
                            fontSize: 12, color: ReaderPalette.inkSoft),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: ReaderPalette.gold, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
