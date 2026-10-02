import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/l10n.dart';
import 'core/reader_session.dart';
import 'core/services/study_db_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/reader_theme.dart';
import 'screens/dummy_bible_reader_screen.dart';
import 'screens/dummy_sermon_notes_screen.dart';

/// The ONE tab-switch duration of the bottom bar — a snappy 150ms cross-fade:
/// fast enough that the selected indicator never appears to lag behind the
/// tap, slow enough to read as one smooth fade. Shared by the amber wash and
/// the icon/label crossfade so the two can never drift out of step.
const Duration _kTabSwitchDuration = Duration(milliseconds: 150);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Saved theme first (bounded wait) so the very first frame already wears it.
  await ReaderThemeController.instance.load();
  // Bookmark / favourite marks load in the background; cards repaint when ready.
  unawaited(StudyStore.instance.load());
  runApp(const ScriptureSermonStudioApp());
}

class ScriptureSermonStudioApp extends StatefulWidget {
  const ScriptureSermonStudioApp({super.key});

  @override
  State<ScriptureSermonStudioApp> createState() =>
      _ScriptureSermonStudioAppState();
}

class _ScriptureSermonStudioAppState extends State<ScriptureSermonStudioApp> {
  @override
  void initState() {
    super.initState();
    ReaderThemeController.instance.id.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ReaderThemeController.instance.id.removeListener(_onThemeChanged);
    super.dispose();
  }

  /// Colours are looked up when widgets build, so after a theme switch every
  /// live element is asked to build again (one frame, only on a user action).
  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {});
    void markDirty(Element element) {
      element.markNeedsBuild();
      element.visitChildren(markDirty);
    }

    (context as Element).visitChildren(markDirty);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Palette.brightness == Brightness.dark;
    final SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: ReaderPalette.canvas,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: MaterialApp(
        title: 'Scripture & Sermon Studio',
        debugShowCheckedModeBanner: false,
        theme: ReadingTheme.current,
        home: const RootShell(),
      ),
    );
  }
}

/// Root shell hosting the bottom navigation bar and the 2 dummy screens.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    ReaderSession.instance.tab.addListener(_onTabRequested);
  }

  @override
  void dispose() {
    ReaderSession.instance.tab.removeListener(_onTabRequested);
    super.dispose();
  }

  /// Sermon Notes asks for the reader (tapped scripture reference) and the
  /// reader asks for the notes (back after such a jump).
  void _onTabRequested() {
    final TabRequest? request = ReaderSession.instance.tab.value;
    if (request == null || !mounted) return;
    if (request.index != _currentIndex) {
      setState(() => _currentIndex = request.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While typing, hide the dock so the keyboard + editor get the full height.
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Back on any tab other than the Reader returns to the Reader first; the
    // Reader itself handles back (undo / exit) only while it is visible.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        backgroundColor: ReaderPalette.canvas,
        body: SafeArea(
          top: false,
          // IndexedStack keeps each screen's local state (scroll position,
          // text being typed) alive when switching tabs.
          child: IndexedStack(
            index: _currentIndex,
            children: [
              DummyBibleReaderScreen(isActive: _currentIndex == 0),
              const DummySermonNotesScreen(),
            ],
          ),
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : ValueListenableBuilder<String>(
                valueListenable: ReaderSession.instance.language,
                builder: (BuildContext context, String lang, Widget? _) {
                  final AppText t = AppText.of(lang);
                  return _FloatingNavigationBar(
                    currentIndex: _currentIndex,
                    labels: <String>[t.navReader, t.navNotes],
                    onTap: (index) => setState(() => _currentIndex = index),
                  );
                },
              ),
      ),
    );
  }
}

/// Describes one destination in the bottom navigation bar.
class _NavSpec {
  const _NavSpec(
      {required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Model-1A warm golden edge-to-edge bottom navigation bar.
/// A warm parchment dock (top radius 20) that spans fully edge-to-edge and
/// hugs the screen bottom, sealed with a soft golden top hairline (#D8B276 @
/// 50%). The active tab gets a soft amber wash (#F3EAD7, r16) inside a
/// 1px golden hairline, wrapping BOTH the icon and its text label in one quiet
/// capsule fired in deep golden ink, while resting tabs render in subtle
/// warm-gray so
/// they stay quiet against the parchment face. Strictly 3 tabs — no "More"
/// button.
class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.currentIndex,
    required this.labels,
    required this.onTap,
  });

  final int currentIndex;

  /// Localised tab labels, in tab order (reader, notes).
  final List<String> labels;
  final ValueChanged<int> onTap;

  List<_NavSpec> get _items => [
        _NavSpec(
            icon: Icons.menu_book_rounded,
            activeIcon: Icons.menu_book_rounded,
            label: labels[0]),
        _NavSpec(
            icon: Icons.edit_note_rounded,
            activeIcon: Icons.edit_note_rounded,
            label: labels[1]),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Model-1A warm golden edge-to-edge dock: zero outer margin so the bar
      // spans fully across the viewport and hugs the screen bottom cleanly.
      margin: EdgeInsets.zero,
      // Slim 6/12 content padding keeps the dock compact vertically.
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      // The dock paints NO `boxShadow` of any kind — it is separated from the
      // content above by its golden top hairline alone. A persistent blur behind
      // the bar used to be re-composited on every `IndexedStack` tab swap, which
      // is exactly what smeared a laggy dark band across the bottom of the
      // screen mid-switch; with zero shadow there is nothing left to
      // re-rasterise, so a switch stays a clean 200ms fade/slide.
      decoration: BoxDecoration(
        // Canvas-matched dock (#F9F6F0 — the same warm sandalwood field the
        // shell paints behind every screen) softly sealed by a golden top
        // hairline (#D8B276 @ 50%), so the bar reads as quiet modern elevation
        // instead of a heavy solid slab.
        color: Palette.c(0xFFFAF2E6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: Palette.c(0xFFD8B276).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (int i = 0; i < _items.length; i++) ...[
              Expanded(
                flex: 1,
                child: _NavItem(
                  icon: _items[i].icon,
                  activeIcon: _items[i].activeIcon,
                  label: _items[i].label,
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single tappable destination inside the bar.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Muted warm-gray (#7A6F60) keeps the resting icon + label quiet on the
    // cream dock (#FAF2E6) without stealing focus from the active tab.
    final Color restingInk = Palette.c(0xFF7A6F60);
    // Warm amber ink (#B87B28) rides on the whisper-soft amber wash so the
    // whole selected tab (icon and label together) reads as one
    // brand-accented unit.
    final Color activeInk = Palette.c(0xFFB87B28);
    return GestureDetector(
      onTap: onTap,
      // heightFactor: 1 keeps the item shrink-wrapped vertically (the
      // Scaffold hands the bottom slot loose, full-height constraints)
      // while still centering the icon + label horizontally.
      child: Center(
        heightFactor: 1,
        // Strict fixed 52px slot for EVERY tab (active and inactive alike),
        // so switching tabs produces zero vertical size jumps or stretching.
        child: SizedBox(
          height: 52,
          child: Center(
            child: AnimatedContainer(
              // ONE snappy 200ms transition — and the amber wash is the ONLY
              // animatable property, so a tab switch can never blink, flicker
              // or shift geometry.
              duration: _kTabSwitchDuration,
              curve: Curves.easeOut,
              // Full-tab active state: a soft amber wash wraps BOTH the
              // icon and the text label inside one unified surface, so the
              // whole destination — not just its icon — highlights when
              // selected. Compact 12/4 padding keeps the pill slim and
              // identical in shape across all tabs.
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                // Active tab wears the soft amber wash (#F3EAD7) over the
                // dock; resting tabs stay transparent with only their muted
                // icon + label.
                color: selected ? Palette.c(0xFFF3EAD7) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                // 1px hairline (transparent while resting, so no geometry ever
                // shifts) frames the wash and echoes the dock's golden seal.
                border: Border.all(
                  color:
                      selected ? Palette.c(0xFFE8D3AC) : Colors.transparent,
                  width: 1.0,
                ),
                // Strictly EMPTY const shadow list on BOTH the active and the
                // inactive state: no `BoxShadow` is ever declared, so none can
                // be interpolated frame-by-frame during the switch — that
                // animated blur was the lingering shadow artifact. The tab
                // lifts through colour + content motion ONLY.
                boxShadow: const [],
              ),
              // The icon + label crossfade through ONE 200ms fade/slide (the
              // same recipe the reader's quick-picker already uses) instead of a
              // hard-cut rebuild, so the newly chosen tab visibly settles into
              // place while the tab being left slides quietly away. Keying the
              // column on [selected] is what drives the switch: no shadow, no
              // blur and no size change ride along with it.
              child: AnimatedSwitcher(
                duration: _kTabSwitchDuration,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  // The key is the entire switch: flipping [selected] swaps the
                  // keyed subtree and fires the fade/slide above.
                  key: ValueKey<bool>(selected),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? activeIcon : icon,
                      size: 20,
                      color: selected ? activeInk : restingInk,
                    ),
                    const SizedBox(height: 2),
                    // FittedBox(scaleDown) guarantees the label occupies
                    // exactly ONE line at all times — long labels such as
                    // "Sermon Notes" or "Prayer Journal" scale down instead
                    // of wrapping, so the pill height never grows.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? activeInk : restingInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
