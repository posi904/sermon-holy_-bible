import 'package:flutter/material.dart';

import '../core/mock_data.dart';
import '../core/services/daily_verse_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/reader_theme.dart';

/// "Verse of the Day" card: a serene motif from `assets/motifs/` under a soft
/// warm-espresso gradient, with cream scripture type on top.
///
/// The scrim is warm and gradual (never black, never a flat block) so the
/// artwork stays visible at the top while the text area keeps high contrast.
class DailyVerseCard extends StatelessWidget {
  final DailyVerse verse;

  /// Language codes to show, in order: 'en', 'te', 'hi'.
  final List<String> languages;

  /// Reference label for a language (e.g. "John 3:16").
  final String Function(DailyVerse verse, String lang) referenceFor;

  final String heading;

  const DailyVerseCard({
    super.key,
    required this.verse,
    required this.languages,
    required this.referenceFor,
    this.heading = 'VERSE OF THE DAY',
  });

  @override
  Widget build(BuildContext context) {
    final List<String> langs = languages.isEmpty ? const ['en'] : languages;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReaderPalette.cardBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/motifs/motif_${verse.motifIndex}.webp',
              fit: BoxFit.cover,
              cacheWidth: 900,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  ColoredBox(color: Palette.c(0xFF6B5A44)),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x3D2A1F16),
                    Color(0xB32A1F16),
                    Color(0xE6241A12),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_twilight_rounded,
                        size: 16, color: Palette.c(0xFFEBD9A8)),
                    const SizedBox(width: 8),
                    Text(
                      heading,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Palette.c(0xFFEBD9A8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                for (int i = 0; i < langs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Text(
                    verse.textFor(langs[i]),
                    style: TextStyle(
                      fontSize: i == 0 ? 18 : 16,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: Palette.c(0xFFF6EFDF)
                          .withValues(alpha: i == 0 ? 1.0 : 0.88),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  '— ${referenceFor(verse, langs.first)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Palette.c(0xFFEBD9A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Book name for a canonical book id (1-66) in the given language code.
String bookNameFor(int bookId, {String lang = 'en'}) {
  if (bookId < 1 || bookId > MockBible.books.length) return '';
  final BookModel b = MockBible.books[bookId - 1];
  switch (lang) {
    case 'te':
      return b.teluguName;
    case 'hi':
      return b.hindiName;
    default:
      return b.englishName;
  }
}
