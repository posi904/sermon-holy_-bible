import 'package:flutter/material.dart';

import 'reader_theme.dart';

/// Centralized design tokens for "Scripture & Sermon Studio".
///
/// Palette is intentionally warm/paper-like to evoke a physical study
/// bible + sermon journal, per the approved visual mockup.
class AppColors {
  AppColors._();

  static const Color sepia = Color(0xFFFBF9F5); // App background
  static const Color cream = Color(0xFFE8E2D6); // Cards / surfaces
  static const Color charcoal = Color(0xFF2E2A24); // Primary text
  static const Color amber = Color(0xFFB8860B); // Accent / highlights
  static const Color blue = Color(0xFF2C5F8A); // Links / secondary accent

  // Derived tones used across the UI (kept here so screens never
  // hardcode ad-hoc colors).
  static const Color charcoalMuted = Color(0xFF6B665C);
  static const Color creamDark = Color(0xFFDCD4C2);
  static const Color divider = Color(0xFFD8D0BE);

  // ==========================================================================
  // Semantic reader tokens (single source of truth)
  // ==========================================================================
  //
  // These SEMANTIC tokens are the ONE authoritative palette for the Bible
  // Reader. Every reader control — language pills, top controls and the
  // Parallel control — resolves its colours from here. Reader screens must
  // never hardcode `Color(0x...)`, `Colors.xxx` or `.withOpacity(...)` for
  // these surfaces.
  //
  //  * [surfacePrimary]   — warm sandalwood parchment app canvas.
  //  * [surfaceSecondary] — warm cream surface for resting controls.
  //  * [textPrimary]      — deep espresso ink for scripture / body copy.
  //  * [textSecondary]    — warm taupe for resting labels & icons.
  //  * [textMuted]        — muted amber-taupe secondary metadata.
  //  * [borderDefault]    — soft sandalwood hairline.
  //  * [borderStrong]     — golden amber micro-contrast hairline.
  //  * [iconPrimary]      — warm amber brand glyph.
  //  * [iconInteractive]  — warm amber for tappable glyphs / active accents.
  //  * [iconOnAccent]     — crisp white content on a solid accent fill.

  static const Color surfacePrimary = Color(0xFFF1EAE0);
  static const Color surfaceSecondary = Color(0xFFFAF2E6);

  /// Warm linen Cream (#FBF8F2) — the ONE paper face of the book-picker tile
  /// and of every resting picker cell (chapter / verse boxes). NEVER pure white:
  /// the faint sand cast is what keeps a 66-row book list and a whole picker
  /// grid reading as one calm, glare-free printed page.
  ///
  /// The verse cards of the reading stack wear their own quiet reading tint —
  /// [verseCardFace] — instead of this cream.
  static const Color warmCream = Color(0xFFFBF8F2);

  /// Soft pale sage reading tint (#F1F5F2) — the ONE background of the verse
  /// cards in the reading stack (every verse card and the closing Verse of the
  /// Day tail). A whisper of cool sage over near-white keeps the paper bright
  /// while taking the glare off a long passage, so even Psalm 119 reads
  /// comfortably; the deep espresso scripture ink (#1C140E) sitting on it
  /// clears WCAG AAA at ~16.5:1 contrast.
  static const Color verseCardFace = Color(0xFFF1F5F2);

  /// Subtle sandalwood hairline (#E8E0D2) framing a [warmCream] tile or a
  /// [verseCardFace] verse card — just enough contrast to draw the panel edge on
  /// the warmer canvas / sheet behind it, without ever hardening into a dark
  /// rule. The hairline is deliberately shared by both faces so a colour change
  /// never redraws a card border.
  static const Color warmCreamBorder = Color(0xFFE8E0D2);

  static const Color textPrimary = Color(0xFF26201D);
  static const Color textSecondary = Color(0xFF7A6F60);
  static const Color textMuted = Color(0xFF9E825A);

  static const Color borderDefault = Color(0xFFD8C4A0);
  static const Color borderStrong = Color(0xFFC48B36);

  static const Color iconPrimary = Color(0xFFB87B28);
  static const Color iconInteractive = iconPrimary;
  static const Color iconOnAccent = Color(0xFFFFFFFF);

  /// Deep espresso tint used to render the reader's micro-elevation shadows.
  static const Color shadow = Color(0xFF2C2523);

  // --------------------------------------------------------------------------
  // Language / control identities
  // --------------------------------------------------------------------------
  //
  // Four approved, intentional identities. Each exposes a deterministic pair:
  //
  //   <identity>Surface  → light tinted UNSELECTED fill (quiet, available)
  //   <identity>Selected → solid SELECTED fill (active, high contrast)
  //
  // All selected fills carry [iconOnAccent] (white) at >= 4.5:1 contrast and
  // every control uses flat solid/tinted fills — never a gradient.
  //
  //  * English  — warm amber / golden brand.
  //  * Telugu   — professional light-green / green family.
  //  * Hindi    — professional pink / rose family.
  //  * Parallel — professional blue.

  // English — warm amber / golden brand.
  static const Color languageEnglishSelected = Color(0xFFA3641C);
  static const Color languageEnglishSurface = Color(0xFFF8EEDA);
  static const Color languageEnglishBorder = Color(0xFFC48B36);

  // Telugu — professional green family.
  static const Color languageTeluguSelected = Color(0xFF3F6B45);
  static const Color languageTeluguSurface = Color(0xFFE9F0E3);
  static const Color languageTeluguBorder = Color(0xFF8FAE7E);

  // Hindi — professional pink / rose family.
  static const Color languageHindiSelected = Color(0xFF9E4E64);
  static const Color languageHindiSurface = Color(0xFFF7E9EC);
  static const Color languageHindiBorder = Color(0xFFD2A6AE);

  // Parallel — professional blue.
  static const Color languageParallelSelected = Color(0xFF2C5F8A);
  static const Color languageParallelSurface = Color(0xFFE7EEF6);
  static const Color languageParallelBorder = Color(0xFF9FB6CC);
}

/// Shared elevation recipes for the reader's micro-elevated floating surfaces.
///
/// Single source of truth for the two shadow depths used across the reader:
/// the 12px tactile lift on header controls/cards and the 1.5dp whisper lift on
/// the warm-cream paper faces (verse cards, book tiles, picker cells). These are
/// legitimate Material elevation effects (soft depth), not decorative gradients.
class AppElevation {
  AppElevation._();

  /// 12px tactile lift for header controls and cards.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  /// 1.5dp whisper lift for the warm-cream paper faces (verse cards, book
  /// tiles, picker cells) — ONE cheap 4px blur instead of the 12px ambient
  /// [card] recipe, so a full chapter of cards or a 66-row book list stays
  /// flat-cost to rasterise while still reading as raised paper.
  static List<BoxShadow> get cream => [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1.5),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.light,
        primary: AppColors.blue,
        secondary: AppColors.amber,
        surface: AppColors.sepia,
      ),
      scaffoldBackgroundColor: AppColors.sepia,
      fontFamily: 'NotoSerif',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cream,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.charcoal,
        selectedItemColor: AppColors.amber,
        unselectedItemColor: Color(0xFFA79E8E),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.charcoal,
        displayColor: AppColors.charcoal,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.cream,
        selectedColor: AppColors.blue,
        labelStyle: const TextStyle(color: AppColors.charcoal),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      iconTheme: const IconThemeData(color: AppColors.charcoal),
      splashColor: AppColors.amber.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
    );
  }
}

/// Material theme for the ACTIVE reading palette (see [Palette]). Rebuilt by
/// the app shell whenever the believer picks another reading theme.
class ReadingTheme {
  ReadingTheme._();

  static ThemeData get current {
    final Brightness b = Palette.brightness;
    final Color ink = ReaderPalette.ink;
    final Color card = ReaderPalette.card;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: ReaderPalette.gold,
      brightness: b,
    ).copyWith(
      primary: ReaderPalette.gold,
      onPrimary: Palette.c(0xFFFFFFFF),
      secondary: ReaderPalette.gold,
      surface: card,
      onSurface: ink,
      onSurfaceVariant: ReaderPalette.inkSoft,
      outline: ReaderPalette.cardBorder,
      outlineVariant: ReaderPalette.cardBorder,
      surfaceContainerLowest: ReaderPalette.canvas,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: card,
      surfaceContainerHighest: ReaderPalette.canvas,
    );
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: ReaderPalette.canvas,
      fontFamily: 'NotoSerif',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      iconTheme: IconThemeData(color: ink),
      dividerColor: ReaderPalette.cardBorder,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ReaderPalette.gold,
        selectionColor: ReaderPalette.gold.withValues(alpha: 0.30),
        selectionHandleColor: ReaderPalette.gold,
      ),
      splashColor: ReaderPalette.gold.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
    );
  }
}

/// Reusable text styles that scale with the reader's font-size preference.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
  );
}

/// Sacred-reading palette shared by the Bible Reader and Sermon Notes so the
/// whole app reads as one continuous parchment page.
///
/// Every value is a warm, low-glare tone: nothing is pure white and nothing is
/// a saturated solid. Ink (#2A1F16) on [card] (#F6EFDF) is ~14:1 contrast
/// (WCAG AAA) yet softer than pure black on white.
class ReaderPalette {
  ReaderPalette._();

  /// Page canvas behind the cards — aged-paper tone.
  static Color get canvas => Palette.c(0xFFEFE6D4);

  /// Verse / note card face — warm study-bible paper.
  static Color get card => Palette.c(0xFFF6EFDF);

  /// Hairline framing cards.
  static Color get cardBorder => Palette.c(0xFFDCCBA8);

  /// Scripture ink.
  static Color get ink => Palette.c(0xFF2A1F16);

  /// Secondary ink (labels, metadata).
  static Color get inkSoft => Palette.c(0xFF6E5B45);

  /// Verse-number medallion.
  static Color get medallion => Palette.c(0xFFE6D7BB);
  static Color get medallionInk => Palette.c(0xFF6B4B29);

  /// Quiet gold used for accents (icons, selected outlines).
  static Color get gold => Palette.c(0xFFB07A2A);

  /// Soft wash used for the "you landed here" verse pulse — a gentle honey
  /// tint, deliberately NOT a bright yellow.
  static Color get pulse => Palette.c(0xFFEBDAB0);
  static Color get pulseBorder => Palette.c(0xFFCFA95F);

  /// Selected chip wash.
  static Color get chipSelected => Palette.c(0xFFEAD9B4);
}
