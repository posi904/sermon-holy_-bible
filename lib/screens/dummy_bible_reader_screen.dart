import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n.dart';
import '../core/mock_data.dart';
import '../core/reader_session.dart';
import '../core/services/bible_db_service.dart';
import '../core/services/daily_verse_service.dart';
import '../core/services/platform_service.dart';
import '../core/services/study_db_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/reader_theme.dart';
import '../core/verse_counts.dart';
import '../widgets/daily_verse_card.dart';
import '../widgets/theme_picker_sheet.dart';
import '../widgets/themed_sheet.dart';
import 'about_screen.dart';
import 'study_screens.dart';

enum ReaderLanguage { telugu, english, hindi }
enum ParallelPair { teluguEnglish, englishHindi, teluguHindi }
enum PickerStep { book, chapter, verse }

extension on BookModel {
  String nameFor(ReaderLanguage language) {
    switch (language) {
      case ReaderLanguage.english:
        return englishName;
      case ReaderLanguage.telugu:
        return teluguName;
      case ReaderLanguage.hindi:
        return hindiName;
    }
  }

  int get bibleId => MockBible.books.indexOf(this) + 1;
}

class _HistoryPoint {
  final BookModel book;
  final int chapter;
  final int verse;
  final double offset;

  const _HistoryPoint({
    required this.book,
    required this.chapter,
    required this.verse,
    this.offset = 0,
  });
}

BoxDecoration get _kParchmentPillDeco => BoxDecoration(
  gradient: LinearGradient(
    colors: [Palette.c(0xFFFFF9ED), Palette.c(0xFFF1E5CF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Palette.c(0xFFD6C5A9), width: 1.0),
  boxShadow: const [
    BoxShadow(color: Color(0x102C2523), blurRadius: 6, offset: Offset(0, 2)),
  ],
);

BoxDecoration get _kActivePillDeco => BoxDecoration(
  color: Palette.c(0xFFF7E6C4),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Palette.c(0xFFC88A2E), width: 1.4),
  boxShadow: const [
    BoxShadow(color: Color(0x1F54380D), blurRadius: 6, offset: Offset(0, 2)),
  ],
);

class DummyBibleReaderScreen extends StatefulWidget {
  /// True while the Bible Reader tab is the visible tab. The reader only
  /// intercepts the Android back gesture while it is on screen, so back on the
  /// Sermon Notes tab is handled by the shell instead.
  final bool isActive;

  const DummyBibleReaderScreen({super.key, this.isActive = true});

  @override
  State<DummyBibleReaderScreen> createState() => _DummyBibleReaderScreenState();
}

class _DummyBibleReaderScreenState extends State<DummyBibleReaderScreen> {
  BookModel? _selectedBook;
  BookModel get _activeBook => _selectedBook ??= MockBible.books.firstWhere(
        (b) => b.englishName == 'John',
        orElse: () => MockBible.books.first,
      );

  int _selectedChapter = 3;
  int _selectedVerse = 0;

  final List<_HistoryPoint> _navigationHistory = [];
  static const int _maxHistory = 40;

  /// Chapters already read from SQLite this session. Undo restores from here
  /// synchronously, so going back never reloads, flickers or resets the page.
  final Map<String, List<VerseModel>> _chapterCache = {};

  DailyVerse? _dailyVerse;

  final ScrollController _listScrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  List<VerseModel> _verses = const <VerseModel>[];
  bool _loadingVerses = true;
  int _verseLoadGeneration = 0;

  bool _parallelMode = true;
  ReaderLanguage _singleLanguage = ReaderLanguage.telugu;
  ParallelPair _parallelPair = ParallelPair.teluguEnglish;
  bool _parallelSwapped = false;
  double _fontScale = 1.0;

  static const double _minScale = 0.8;
  static const double _maxScale = 1.6;

  /// Last verse of the chosen passage (== [_selectedVerse] for one verse).
  int _selectedVerseEnd = 0;

  /// The passage the reader just landed on. The highlight is PERSISTENT (there
  /// is no reset timer), so the reader can scroll away and still spot it; it
  /// is only replaced by choosing another verse or another chapter. It is tied
  /// to the chapter it was chosen in ([_highlightKey]) so it can never paint a
  /// same-numbered verse of the chapter being left behind.
  int _highlightFrom = 0;
  int _highlightTo = 0;
  String? _highlightKey;

  /// "bookId:chapter" of the chapter whose verses are on screen right now.
  String? _displayedKey;

  /// Bumped for every landing request so a stale request stands down.
  int _landingToken = 0;

  /// The verse the reader jumped away from, tracked ONLY while the jump stays
  /// inside the current chapter. Android back silently returns here and clears
  /// it; it never reaches back into a previous book.
  int? _previousVerseNumber;

  /// Set the moment the reader taps a verse inside the quick picker. Android
  /// back spends it once to re-open that sheet straight on the verse grid, so a
  /// mis-tap is one back press away from being corrected. Any other back path
  /// stays untouched.
  bool _canQuickBackToVersePicker = false;

  DateTime? _lastBackPressAt;
  static const Duration _kExitConfirmWindow = Duration(seconds: 2);

  /// Bookmark / favourite / share actions on a verse card refer to the chapter
  /// that is actually ON SCREEN (the selected chapter can run ahead of it for
  /// a moment while the next chapter loads).
  int _displayedBookId = 0;
  int _displayedChapter = 0;

  final GlobalKey _scrollViewKey = GlobalKey();
  Timer? _readLogTimer;

  /// A landing requested while the Bible tab was hidden; it runs the moment
  /// the tab is shown again (a hidden tab cannot scroll reliably).
  int? _pendingLandVerse;

  void _setFontScale(double value) {
    setState(() => _fontScale = value.clamp(_minScale, _maxScale));
    unawaited(StudyDbService.instance
        .setSetting('font_scale', _fontScale.toStringAsFixed(1)));
  }

  void _increaseFont() => _setFontScale(_fontScale + 0.1);

  void _decreaseFont() => _setFontScale(_fontScale - 0.1);

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  void initState() {
    super.initState();
    _loadVerses();
    ReaderSession.instance.jump.addListener(_onJumpRequested);
    StudyDbService.instance.getSetting('font_scale').then((String? v) {
      final double? saved = double.tryParse(v ?? '');
      if (mounted && saved != null) {
        setState(() => _fontScale = saved.clamp(_minScale, _maxScale));
      }
    }).catchError((Object _) {});
    DailyVerseService.load().then((DailyVerse? v) {
      if (mounted && v != null) setState(() => _dailyVerse = v);
    });
  }

  @override
  void didUpdateWidget(covariant DummyBibleReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int? pending = _pendingLandVerse;
    if (widget.isActive && !oldWidget.isActive && pending != null) {
      _pendingLandVerse = null;
      _landOnVerse(pending, animate: false);
    }
  }

  @override
  void dispose() {
    _readLogTimer?.cancel();
    ReaderSession.instance.jump.removeListener(_onJumpRequested);
    _listScrollController.dispose();
    super.dispose();
  }

  int _bookIdFor(BookModel book) => MockBible.books.indexOf(book) + 1;

  VerseModel _verseModelFromRow(Map<String, dynamic> row) => VerseModel(
        verseNumber: '${row['verse']}',
        english: (row['en'] as String?) ?? '',
        telugu: (row['te'] as String?) ?? '',
        textHindi: (row['hi'] as String?) ?? '',
      );

  String _cacheKey(BookModel book, int chapter) => '${_bookIdFor(book)}:$chapter';

  void _applyVerses(
      List<VerseModel> verses, String key, int bookId, int chapter) {
    setState(() {
      _verses = verses;
      _displayedKey = key;
      _displayedBookId = bookId;
      _displayedChapter = chapter;
      _verseKeys.clear();
      for (final v in _verses) {
        final int? n = int.tryParse(v.verseNumber);
        if (n != null) _verseKeys[n] = GlobalKey();
      }
      _loadingVerses = false;
    });
  }

  Future<void> _loadVerses({double? restoreOffset}) async {
    final int generation = ++_verseLoadGeneration;
    final BookModel book = _activeBook;
    final int chapter = _selectedChapter;
    final String cacheKey = _cacheKey(book, chapter);

    // The chapter is already on screen (e.g. choosing another verse of it):
    // keep the existing cards untouched and simply land on the verse.
    if (_displayedKey == cacheKey && _verses.isNotEmpty) {
      _afterLoad(restoreOffset, freshChapter: false);
      return;
    }

    final List<VerseModel>? cached = _chapterCache[cacheKey];
    if (cached != null) {
      _applyVerses(cached, cacheKey, _bookIdFor(book), chapter);
      _afterLoad(restoreOffset, freshChapter: true);
      return;
    }

    bool loaded = false;
    try {
      final List<Map<String, dynamic>> rows =
          await BibleDbService.instance.getVerses(
        bookId: _bookIdFor(book),
        chapter: chapter,
      );
      if (!mounted || generation != _verseLoadGeneration) return;
      final List<VerseModel> verses = <VerseModel>[
        for (final Map<String, dynamic> row in rows) _verseModelFromRow(row)
      ];
      if (_chapterCache.length >= 16) {
        _chapterCache.remove(_chapterCache.keys.first);
      }
      _chapterCache[cacheKey] = verses;
      _applyVerses(verses, cacheKey, _bookIdFor(book), chapter);
      loaded = true;
    } catch (_) {
      if (!mounted || generation != _verseLoadGeneration) return;
      setState(() {
        _verses = const <VerseModel>[];
        _displayedKey = null;
        _loadingVerses = false;
      });
    }

    if (loaded && mounted && generation == _verseLoadGeneration) {
      _afterLoad(restoreOffset, freshChapter: true);
    }
  }

  void _afterLoad(double? restoreOffset, {required bool freshChapter}) {
    _scheduleReadLog();
    if (restoreOffset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_listScrollController.hasClients) return;
        final ScrollPosition pos = _listScrollController.position;
        _listScrollController
            .jumpTo(restoreOffset.clamp(0.0, pos.maxScrollExtent));
      });
    } else if (_selectedVerse > 0) {
      // A chapter that was just swapped in is landed on instantly (nothing to
      // animate from); a verse inside the chapter already on screen glides.
      _landOnVerse(_selectedVerse, animate: !freshChapter);
    } else {
      _landingToken++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _listScrollController.hasClients) {
          _listScrollController.jumpTo(0);
        }
      });
    }
  }

  /// Logs the chapter as "read" once the believer has stayed on it for a few
  /// seconds, so quick page-flipping does not flood the history.
  void _scheduleReadLog() {
    _readLogTimer?.cancel();
    final int bookId = _displayedBookId;
    final int chapter = _displayedChapter;
    if (bookId == 0 || chapter == 0) return;
    _readLogTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !widget.isActive) return;
      unawaited(StudyDbService.instance
          .logRead(bookId, chapter, _selectedVerse));
    });
  }

  /// Marks [from]..[to] (default: just [from]) as the chosen passage of the
  /// CURRENT book/chapter. Call inside setState, after updating them.
  void _setSelection(int from, [int? to]) {
    final int end = (to == null || to < from) ? from : to;
    _selectedVerse = from;
    _selectedVerseEnd = end;
    _highlightFrom = from;
    _highlightTo = end;
    _highlightKey = _cacheKey(_activeBook, _selectedChapter);
  }

  bool _isHighlighted(int verseNumber) =>
      _highlightFrom > 0 &&
      _highlightKey != null &&
      _highlightKey == _displayedKey &&
      verseNumber >= _highlightFrom &&
      verseNumber <= _highlightTo;

  /// The verse to scroll to for [verse]: itself, or the nearest earlier verse
  /// when a reference points past the end of the chapter.
  int _resolveVerse(int verse) {
    if (_verseKeys.containsKey(verse)) return verse;
    int best = 0;
    int first = 0;
    for (final int n in _verseKeys.keys) {
      if (n <= verse && n > best) best = n;
      if (first == 0 || n < first) first = n;
    }
    return best > 0 ? best : (first > 0 ? first : verse);
  }

  /// Scrolls so [verse] sits comfortably in the upper third of the viewport.
  ///
  /// Built to survive slow, low-memory phones:
  ///  * the whole chapter is laid out up-front, so the verse always has a real
  ///    position (no height guesses);
  ///  * the request waits (frame by frame, up to ~40 frames) until the verse
  ///    is actually on screen, and until the Bible tab is visible;
  ///  * after the first scroll it re-checks the position three more times
  ///    (late font / layout changes can nudge a slow device) and corrects any
  ///    drift, unless the reader has started scrolling by hand;
  ///  * every request carries a token, so a newer pick cancels an older one.
  void _landOnVerse(int verse, {bool animate = true}) {
    final int token = ++_landingToken;
    _landAttempt(verse, token, animate, 0);
  }

  void _landAttempt(int verse, int token, bool animate, int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || token != _landingToken) return;
      if (!widget.isActive) {
        _pendingLandVerse = verse;
        return;
      }
      final BuildContext? ctx = _verseKeys[_resolveVerse(verse)]?.currentContext;
      final bool ready = ctx != null &&
          ctx.mounted &&
          _listScrollController.hasClients &&
          _listScrollController.position.hasContentDimensions;
      if (!ready) {
        if (attempt < 40) {
          _landAttempt(verse, token, animate, attempt + 1);
          WidgetsBinding.instance.scheduleFrame();
        }
        return;
      }
      await _alignNow(verse, animate: animate);
      for (final int ms in const <int>[120, 350, 900]) {
        await Future<void>.delayed(Duration(milliseconds: ms));
        if (!mounted || token != _landingToken) return;
        _realign(verse);
      }
    });
  }

  Future<void> _alignNow(int verse, {required bool animate}) {
    final BuildContext? ctx = _verseKeys[_resolveVerse(verse)]?.currentContext;
    if (ctx == null || !ctx.mounted) return Future<void>.value();
    return Scrollable.ensureVisible(
      ctx,
      duration: animate ? const Duration(milliseconds: 380) : Duration.zero,
      curve: Curves.easeInOutCubic,
      alignment: 0.3,
    );
  }

  void _realign(int verse) {
    final BuildContext? ctx = _verseKeys[_resolveVerse(verse)]?.currentContext;
    if (ctx == null || !ctx.mounted || !_listScrollController.hasClients) return;
    if (!_isAligned(ctx)) {
      Scrollable.ensureVisible(ctx, alignment: 0.3);
    }
  }

  /// True when the verse card sits where [_alignNow] puts it (or as close as
  /// the ends of the chapter allow).
  bool _isAligned(BuildContext ctx) {
    final RenderObject? card = ctx.findRenderObject();
    final RenderObject? view = _scrollViewKey.currentContext?.findRenderObject();
    if (card is! RenderBox || view is! RenderBox) return true;
    if (!card.hasSize || !view.hasSize || !card.attached) return true;
    final double top = card.localToGlobal(Offset.zero, ancestor: view).dy;
    final double expected = (view.size.height - card.size.height) * 0.3;
    if ((top - expected).abs() <= 10) return true;
    final ScrollPosition pos = _listScrollController.position;
    final bool pinnedAtEnd =
        top > expected && pos.pixels >= pos.maxScrollExtent - 1;
    final bool pinnedAtStart =
        top < expected && pos.pixels <= pos.minScrollExtent + 1;
    return pinnedAtEnd || pinnedAtStart;
  }

  /// Opens the exact passage requested from elsewhere in the app (Sermon
  /// Notes). Same landing path as the picker, so behaviour is identical.
  void _onJumpRequested() {
    final ScriptureJump? j = ReaderSession.instance.jump.value;
    if (j == null || !mounted) return;
    if (j.bookId < 1 || j.bookId > MockBible.books.length) return;
    final BookModel book = MockBible.books[j.bookId - 1];
    final int chapter = j.chapter.clamp(1, book.chapterCount);
    _pushHistory();
    setState(() {
      _previousVerseNumber = null;
      _canQuickBackToVersePicker = false;
      _selectedBook = book;
      _selectedChapter = chapter;
      if (j.verseStart > 0) {
        _setSelection(j.verseStart, j.verseEnd);
      } else {
        _selectedVerse = 0;
        _selectedVerseEnd = 0;
        _highlightFrom = 0;
        _highlightTo = 0;
      }
    });
    // After _pushHistory (which clears it): back returns to the note.
    ReaderSession.instance.returnToNotes = j.fromNotes;
    _loadVerses();
  }

  /// Publishes the reader's primary language so Sermon Notes and the
  /// navigation bar follow it. Deferred to after the frame: it must never
  /// notify listeners in the middle of a build.
  void _syncSessionLanguage() {
    final String code = _langCode(_primaryLanguage);
    if (ReaderSession.instance.language.value == code) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ReaderSession.instance.language.value = _langCode(_primaryLanguage);
      }
    });
  }

  _HistoryPoint _currentPoint() => _HistoryPoint(
        book: _activeBook,
        chapter: _selectedChapter,
        verse: _selectedVerse,
        offset: _listScrollController.hasClients
            ? _listScrollController.offset
            : 0,
      );

  void _pushHistory() {
    // Any navigation the reader makes on its own ends the "back returns to my
    // sermon note" shortcut.
    ReaderSession.instance.returnToNotes = false;
    _navigationHistory.add(_currentPoint());
    if (_navigationHistory.length > _maxHistory) {
      _navigationHistory.removeAt(0);
    }
  }

  ReaderLanguage get _primaryLanguage {
    if (!_parallelMode) return _singleLanguage;
    final pair = _pairLanguages(_parallelPair);
    return _parallelSwapped ? pair[1] : pair[0];
  }

  List<ReaderLanguage> get _activeLanguages {
    if (!_parallelMode) {
      return [_singleLanguage];
    }
    final pair = _pairLanguages(_parallelPair);
    return _parallelSwapped ? [pair[1], pair[0]] : pair;
  }

  List<ReaderLanguage> _pairLanguages(ParallelPair pair) {
    switch (pair) {
      case ParallelPair.teluguEnglish:
        return const [ReaderLanguage.telugu, ReaderLanguage.english];
      case ParallelPair.englishHindi:
        return const [ReaderLanguage.english, ReaderLanguage.hindi];
      case ParallelPair.teluguHindi:
        return const [ReaderLanguage.telugu, ReaderLanguage.hindi];
    }
  }

  String _verseText(VerseModel verse, ReaderLanguage language) {
    switch (language) {
      case ReaderLanguage.english:
        return verse.english;
      case ReaderLanguage.telugu:
        return verse.telugu;
      case ReaderLanguage.hindi:
        return verse.textHindi;
    }
  }

  TextStyle _verseStyle() => TextStyle(
        fontSize: 17.0 * _fontScale,
        height: 1.65,
        color: ReaderPalette.ink,
        fontWeight: FontWeight.w500,
      );

  Future<void> _openQuickPicker({PickerStep initialStep = PickerStep.book}) async {
    final result = await showModalBottomSheet<_QuickPickerResult>(
      context: context,
      backgroundColor: Palette.c(0xFFEDE3D0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _QuickPickerSheet(
        primaryLanguage: _primaryLanguage,
        initialBook: _activeBook,
        initialChapter: _selectedChapter,
        initialVerse: _selectedVerse,
        initialStep: initialStep,
      ),
    );

    if (result != null && mounted) {
      // A verse cell was tapped, so arm the one-shot back shortcut before the
      // early return below: re-picking the same verse is still a verse pick.
      _canQuickBackToVersePicker = true;
      final bool samePlace = result.book == _activeBook &&
          result.chapter == _selectedChapter &&
          result.verse == _selectedVerse;
      if (samePlace) {
        // Re-picking the verse already chosen: bring it back into view (the
        // reader may have scrolled away from it).
        _landOnVerse(result.verse);
        return;
      }
      _pushHistory();
      setState(() {
        // Remember where we came from ONLY when the jump stays inside the
        // current chapter, so back can silently return to that verse. Changing
        // chapter or book drops the memory entirely — back never reaches back
        // into a previous book.
        final bool sameChapter =
            result.book == _activeBook && result.chapter == _selectedChapter;
        _previousVerseNumber =
            (sameChapter && _selectedVerse > 0) ? _selectedVerse : null;
        _selectedBook = result.book;
        _selectedChapter = result.chapter;
        _setSelection(result.verse);
      });
      _loadVerses();
    }
  }

  void _nextChapter() {
    if (_selectedChapter < _activeBook.chapterCount) {
      _pushHistory();
      setState(() {
        _selectedChapter++;
        _selectedVerse = 0;
        // A new chapter ends both the in-chapter back memory and the
        // persistent verse highlight.
        _previousVerseNumber = null;
        _selectedVerseEnd = 0;
        _highlightFrom = 0;
        _highlightTo = 0;
      });
      _loadVerses();
    }
  }

  void _previousChapter() {
    if (_selectedChapter > 1) {
      _pushHistory();
      setState(() {
        _selectedChapter--;
        _selectedVerse = 0;
        _previousVerseNumber = null;
        _selectedVerseEnd = 0;
        _highlightFrom = 0;
        _highlightTo = 0;
      });
      _loadVerses();
    }
  }

  void _handleAndroidBack() {
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      Navigator.of(context).pop();
      return;
    }

    // Arrived from a Sermon Notes reference: back returns to the note.
    if (ReaderSession.instance.returnToNotes) {
      ReaderSession.instance.showNotes();
      return;
    }

    // Quick recovery: the reader just tapped a verse in the picker, so back
    // re-opens the sheet directly on the verse grid instead of falling through
    // to scroll-to-top or exit. The flag is spent on use, so the next back
    // resumes the normal chain below.
    if (_canQuickBackToVersePicker) {
      _canQuickBackToVersePicker = false;
      _openQuickPicker(initialStep: PickerStep.verse);
      return;
    }

    // Silent in-chapter back: return to the verse the reader jumped away from,
    // then forget it. This is scoped to the CURRENT chapter by construction —
    // back never navigates into a previous book.
    final int? previousVerse = _previousVerseNumber;
    if (previousVerse != null) {
      setState(() {
        _setSelection(previousVerse);
        _previousVerseNumber = null;
      });
      _landOnVerse(previousVerse);
      return;
    }

    if (_listScrollController.hasClients && _listScrollController.offset > 24) {
      _listScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? previous = _lastBackPressAt;
    if (previous != null && now.difference(previous) <= _kExitConfirmWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPressAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_primaryLanguage == ReaderLanguage.english
              ? 'Press back again to exit'
              : _primaryLanguage == ReaderLanguage.hindi
                  ? 'बाहर निकलने के लिए फिर से वापस दबाएं'
                  : 'బయటకు వెళ్లడానికి మరోసారి బ్యాక్ నొక్కండి'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    _syncSessionLanguage();
    return PopScope(
      canPop: !widget.isActive,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleAndroidBack();
      },
      child: Scaffold(
        backgroundColor: ReaderPalette.canvas,
        body: SafeArea(
          child: Column(
            children: [
              _buildSelectorBar(),
              _buildViewModeToggle(),
              Divider(height: 1, color: ReaderPalette.cardBorder),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -250) {
                        _nextChapter();
                      } else if (details.primaryVelocity! > 250) {
                        _previousChapter();
                      }
                    }
                  },
                  child: _buildVerseList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorBar() {
    // No header undo button: the book selector pill takes the FULL remaining
    // row width, so canonical book titles never truncate into an ellipsis.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(child: _buildBookSelectorPill()),
          const SizedBox(width: 6),
          _buildVersePickerButton(),
          const SizedBox(width: 6),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildBookSelectorPill() {
    final ReaderLanguage language = _primaryLanguage;
    final String name = _selectedBook?.nameFor(language) ??
        _selectedBook?.teluguName ??
        'యోహాను';
    final String canonicalBookName =
        _formatCanonicalBookName(name, _languageLabel(language));
    final String refTail = _selectedVerse > 0
        ? (_selectedVerseEnd > _selectedVerse
            ? ' $_selectedChapter:$_selectedVerse-$_selectedVerseEnd'
            : ' $_selectedChapter:$_selectedVerse')
        : ' $_selectedChapter';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _openQuickPicker,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.c(0xFFFFF9EE), Palette.c(0xFFF4E6CE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.c(0xFFD6C5A9), width: 1.0),
          boxShadow: const [
            BoxShadow(color: Color(0x122C2523), blurRadius: 4, offset: Offset(0, 1.5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Palette.c(0xFFEAD4B5), Palette.c(0xFFDFC6A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Palette.c(0xFFCDAF85), width: 1.0),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: Palette.c(0xFF6B4B29),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                canonicalBookName,
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: Palette.c(0xFF261D16),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              refTail,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w800,
                color: Palette.c(0xFF261D16),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 22,
              color: Palette.c(0xFFB87B28),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCanonicalBookName(String rawName, String lang) {
    String name = rawName.trim();
    if (lang != 'తెలుగు') return name;

    if (name.contains('మొదటి') || name.startsWith('1')) {
      final String stem = name
          .replaceAll('మొదటి', '')
          .replaceAll('1', '')
          .replaceAll('వ ', ' ')
          .trim();
      name = '1 $stem';
    } else if (name.contains('రెండవ') || name.startsWith('2')) {
      final String stem = name
          .replaceAll('రెండవ', '')
          .replaceAll('2', '')
          .replaceAll('వ ', ' ')
          .trim();
      name = '2 $stem';
    } else if (name.contains('మూడవ') || name.startsWith('3')) {
      final String stem = name
          .replaceAll('మూడవ', '')
          .replaceAll('3', '')
          .replaceAll('వ ', ' ')
          .trim();
      name = '3 $stem';
    }

    name = name
        .replaceAll('గ్రంథము', '')
        .replaceAll('కాండము', '')
        .replaceAll('కార్యములు', '')
        .replaceAll('పత్రిక', '')
        .replaceAll('దినవృత్తాంతములు', 'దినవృ.')
        .replaceAll('కొరింథీయులకు', 'కొరింథీ')
        .replaceAll('దెస్సలొనీకయులకు', 'దెస్సలొనీక')
        .replaceAll('థెస్సలొనీకయులకు', 'థెస్సలొనీక')
        .replaceAll('తిమోతికి', 'తిమోతి')
        .trim();

    return name;
  }

  /// One tap back to the verse grid of the CURRENT chapter — the quick way to
  /// fix a mis-tapped verse without going through book and chapter again.
  Widget _buildVersePickerButton() => _HeaderActionIcon(
        icon: Icons.format_list_numbered_rounded,
        onTap: () => _openQuickPicker(initialStep: PickerStep.verse),
      );

  Widget _buildSettingsButton() => _HeaderActionIcon(
        icon: Icons.settings_rounded,
        onTap: _showSettingsSheet,
      );

  Widget _buildViewModeToggle() {
    final List<Widget> cells = [
      _buildLanguageChip(ReaderLanguage.english),
      _buildLanguageChip(ReaderLanguage.telugu),
      _buildLanguageChip(ReaderLanguage.hindi),
      _buildParallelPill(),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(flex: i == 3 ? 5 : 4, child: cells[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageChip(ReaderLanguage language) {
    final selected = !_parallelMode && _singleLanguage == language;
    return GestureDetector(
      onTap: () => setState(() {
        _parallelMode = false;
        _singleLanguage = language;
      }),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                color: Palette.c(0xFFE8D3B2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Palette.c(0xFFC88A2E), width: 1.4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18C88A2E),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [Palette.c(0xFFFFF9ED), Palette.c(0xFFF1E5CF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Palette.c(0xFFD6C5A9), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C2C2523),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
        child: Text(
          _languageLabel(language),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Palette.c(0xFF38230D) : Palette.c(0xFF6B5844),
          ),
        ),
      ),
    );
  }

  String _languageLabel(ReaderLanguage language) {
    switch (language) {
      case ReaderLanguage.english:
        return 'English';
      case ReaderLanguage.telugu:
        return 'తెలుగు';
      case ReaderLanguage.hindi:
        return 'हिन्दी';
    }
  }

  String _nativeCode(ReaderLanguage language) {
    switch (language) {
      case ReaderLanguage.english:
        return 'EN';
      case ReaderLanguage.telugu:
        return 'TE';
      case ReaderLanguage.hindi:
        return 'HI';
    }
  }

  Widget _buildParallelPill() {
    final pair = _pairLanguages(_parallelPair);
    final leading = _parallelSwapped ? pair[1] : pair[0];
    final trailing = _parallelSwapped ? pair[0] : pair[1];

    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: _parallelMode
          ? BoxDecoration(
              color: Palette.c(0xFFE8D3B2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Palette.c(0xFFC88A2E), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18C88A2E),
                  blurRadius: 4,
                  offset: Offset(0, 1.5),
                ),
              ],
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [Palette.c(0xFFFFF9ED), Palette.c(0xFFF1E5CF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Palette.c(0xFFD6C5A9), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C2C2523),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _parallelMode = true;
                _parallelSwapped = !_parallelSwapped;
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: Palette.c(0xFF38230D)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${_nativeCode(leading)} | ${_nativeCode(trailing)}',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _parallelMode ? FontWeight.w700 : FontWeight.w600,
                        color: _parallelMode ? Palette.c(0xFF38230D) : Palette.c(0xFF6B5844),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<ParallelPair>(
            tooltip: 'భాషల జంట ఎంపిక',
            padding: EdgeInsets.zero,
            onSelected: (pair) => setState(() {
              _parallelMode = true;
              _parallelPair = pair;
              _parallelSwapped = false;
            }),
            itemBuilder: (context) => [
              for (final p in ParallelPair.values)
                PopupMenuItem(
                  value: p,
                  child: Text(_pairMenuLabel(p)),
                ),
            ],
            child: Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.arrow_drop_down, size: 16, color: Palette.c(0xFF38230D)),
            ),
          ),
        ],
      ),
    );
  }

  String _pairMenuLabel(ParallelPair pair) {
    switch (pair) {
      case ParallelPair.teluguEnglish:
        return 'తెలుగు + English';
      case ParallelPair.englishHindi:
        return 'English + हिन्दी';
      case ParallelPair.teluguHindi:
        return 'తెలుగు + हिन्दी';
    }
  }

  /// The whole chapter is laid out in one scroll view rather than a lazy
  /// list. A chapter is only text (at most 176 short verses), so this is cheap
  /// even on 2 GB phones, and it is what makes verse landing exact: every
  /// verse's GlobalKey has a live context, so `Scrollable.ensureVisible` never
  /// has to guess the position of an unbuilt row.
  Widget _buildVerseList() {
    final bool loading = _loadingVerses && _verses.isEmpty;
    final bool failed = !_loadingVerses && _verses.isEmpty;
    final AppText text = AppText.of(_langCode(_primaryLanguage));
    return NotificationListener<ScrollStartNotification>(
      // The believer took over the scroll: stop any landing correction.
      onNotification: (ScrollStartNotification n) {
        if (n.dragDetails != null) _landingToken++;
        return false;
      },
      child: SingleChildScrollView(
        key: _scrollViewKey,
        controller: _listScrollController,
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 96),
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
              )
            else if (failed)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 96, 32, 0),
                child: Column(
                  children: [
                    Text(text.loadFailed,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, color: ReaderPalette.inkSoft)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _loadingVerses = true);
                        _loadVerses();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(text.retry),
                    ),
                  ],
                ),
              )
            else ...[
              for (final VerseModel verse in _verses) _buildVerseCard(verse),
              _buildDailyVerseTail(),
              _buildChapterNavCard(),
            ],
          ],
        ),
      ),
    );
  }

  // Authentic Warm Cream Verse Card with High Contrast against the canvas
  Widget _buildVerseCard(VerseModel verse) {
    final verseNum = int.tryParse(verse.verseNumber) ?? 0;
    final isHighlighted = _isHighlighted(verseNum);
    final cardKey = _verseKeys[verseNum];

    Widget textFor(ReaderLanguage language) =>
        Text(_verseText(verse, language), style: _verseStyle());

    final languages = _activeLanguages;

    return AnimatedContainer(
      key: cardKey,
      // Fast, gentle wash-in; slow, quiet fade-out.
      duration: Duration(milliseconds: isHighlighted ? 320 : 900),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted ? ReaderPalette.pulse : ReaderPalette.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isHighlighted
              ? ReaderPalette.pulseBorder
              : ReaderPalette.cardBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122C2523),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ReaderPalette.medallion,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  verse.verseNumber,
                  style: TextStyle(
                    color: Palette.c(0xFF704D28),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _buildVerseActions(verse, verseNum),
            ],
          ),
          const SizedBox(height: 10),
          if (languages.length == 1)
            textFor(languages.single)
          else ...[
            textFor(languages[0]),
            const SizedBox(height: 12),
            textFor(languages[1]),
          ],
        ],
      ),
    );
  }

  Widget _verseActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: SizedBox(
            width: 38,
            height: 34,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      );

  /// Share / favourite / bookmark for one verse. The two toggles read an
  /// in-memory mirror of the database, so they respond on the very tap.
  Widget _buildVerseActions(VerseModel verse, int verseNum) {
    final AppText t = AppText.of(_langCode(_primaryLanguage));
    return ValueListenableBuilder<int>(
      valueListenable: StudyStore.instance.revision,
      builder: (BuildContext context, int revision, Widget? child) {
        final bool favorite = StudyStore.instance.isSaved(
            StudyDbService.kFavorite, _displayedBookId, _displayedChapter, verseNum);
        final bool bookmarked = StudyStore.instance.isSaved(
            StudyDbService.kBookmark, _displayedBookId, _displayedChapter, verseNum);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _verseActionButton(
              icon: Icons.ios_share_rounded,
              tooltip: t.shareVerse,
              color: Palette.c(0xFF704D28),
              onTap: () => _shareVerse(verse),
            ),
            _verseActionButton(
              icon: favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              tooltip: t.favorites,
              color: favorite ? ReaderPalette.gold : Palette.c(0xFF8C7358),
              onTap: () => _toggleSaved(StudyDbService.kFavorite, verse, verseNum),
            ),
            _verseActionButton(
              icon: bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              tooltip: t.bookmarks,
              color: bookmarked ? ReaderPalette.gold : Palette.c(0xFF8C7358),
              onTap: () => _toggleSaved(StudyDbService.kBookmark, verse, verseNum),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleSaved(String kind, VerseModel verse, int verseNum) async {
    if (verseNum <= 0 || _displayedBookId == 0) return;
    await StudyStore.instance.toggle(
      kind,
      bookId: _displayedBookId,
      chapter: _displayedChapter,
      verse: verseNum,
      en: _verseText(verse, ReaderLanguage.english),
      te: _verseText(verse, ReaderLanguage.telugu),
      hi: _verseText(verse, ReaderLanguage.hindi),
    );
  }

  Future<void> _shareVerse(VerseModel verse) async {
    final String lang = _langCode(_primaryLanguage);
    final String reference =
        '${localizedBookName(_displayedBookId, lang)} $_displayedChapter:${verse.verseNumber}';
    final String body = <String>[
      for (final ReaderLanguage l in _activeLanguages) _verseText(verse, l),
    ].join('\n\n');
    final String text = '$body\n\u2014 $reference';
    final bool shown = await PlatformService.share(text);
    if (shown || !mounted) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _notify(AppText.of(lang).copied);
  }

  String _langCode(ReaderLanguage l) => l == ReaderLanguage.telugu
      ? 'te'
      : l == ReaderLanguage.hindi
          ? 'hi'
          : 'en';

  Widget _buildDailyVerseTail() {
    final DailyVerse? dv = _dailyVerse;
    if (dv == null || _verses.isEmpty) return const SizedBox.shrink();
    return DailyVerseCard(
      verse: dv,
      languages: [for (final l in _activeLanguages) _langCode(l)],
      heading: _primaryLanguage == ReaderLanguage.english
          ? 'VERSE OF THE DAY'
          : _primaryLanguage == ReaderLanguage.hindi
              ? 'आज का वचन'
              : 'నేటి వాక్యం',
      referenceFor: (v, lang) =>
          '${bookNameFor(v.bookId, lang: lang)} ${v.chapter}:${v.verse}',
    );
  }

  Widget _buildChapterNavCard() {
    final bool hasPrev = _selectedChapter > 1;
    final bool hasNext = _selectedChapter < _activeBook.chapterCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.c(0xFFF6EBD9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.c(0xFFDAC5A3)),
        boxShadow: const [
          BoxShadow(color: Color(0x102C2523), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: hasPrev ? _previousChapter : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _primaryLanguage == ReaderLanguage.english
                    ? '← Previous Chapter'
                    : _primaryLanguage == ReaderLanguage.hindi
                        ? '← पिछला अध्याय'
                        : '← మునుపటి అధ్యాయం',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: Palette.c(0xFF5A442E)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$_selectedChapter / ${_activeBook.chapterCount}',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Palette.c(0xFF8C7358)),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: hasNext ? _nextChapter : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _primaryLanguage == ReaderLanguage.english
                    ? 'Next Chapter →'
                    : _primaryLanguage == ReaderLanguage.hindi
                        ? 'अगला अध्याय →'
                        : 'తర్వాతి అధ్యాయం →',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: Palette.c(0xFF5A442E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    final AppText t = AppText.of(_langCode(_primaryLanguage));
    showThemedSheet<void>(
      context,
      builder: (BuildContext sheetContext) {
        void open(Widget screen) {
          final NavigatorState nav = Navigator.of(sheetContext);
          nav.pop();
          nav.push(MaterialPageRoute<void>(builder: (_) => screen));
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Palette.c(0xFFCDAF85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.settingsTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Palette.c(0xFF261D16),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Palette.c(0xFF261D16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                StatefulBuilder(
                  builder: (context, setSheetState) => _FontSizeSettingTile(
                    percent: (_fontScale * 100).round(),
                    onDecrease: _fontScale > _minScale
                        ? () {
                            _decreaseFont();
                            setSheetState(() {});
                          }
                        : null,
                    onIncrease: _fontScale < _maxScale
                        ? () {
                            _increaseFont();
                            setSheetState(() {});
                          }
                        : null,
                  ),
                ),
                _SettingsTile(
                  emoji: '\u{1F516}',
                  label: t.bookmarks,
                  onTap: () => open(
                      const SavedVersesScreen(kind: StudyDbService.kBookmark)),
                ),
                _SettingsTile(
                  emoji: '\u2B50',
                  label: t.favorites,
                  onTap: () => open(
                      const SavedVersesScreen(kind: StudyDbService.kFavorite)),
                ),
                _SettingsTile(
                  emoji: '\u{1F552}',
                  label: t.readingHistory,
                  onTap: () => open(const ReadingHistoryScreen()),
                ),
                _SettingsTile(
                  emoji: '\u{1F3A8}',
                  label: t.readingTheme,
                  onTap: () => showThemedSheet<void>(
                    sheetContext,
                    builder: (_) => ThemePickerSheet(text: t),
                  ),
                ),
                _SettingsTile(
                  emoji: '\u{1F31F}',
                  label: t.rateApp,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final bool opened = await PlatformService.openStorePage();
                    if (!opened && mounted) _notify(t.storeOpenFailed);
                  },
                ),
                _SettingsTile(
                  emoji: '\u{1F4E4}',
                  label: t.shareApp,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final String message = t.shareAppMessage(PlatformService.storeUrl);
                    final bool shown = await PlatformService.share(message);
                    if (shown || !mounted) return;
                    await Clipboard.setData(ClipboardData(text: message));
                    if (mounted) _notify(t.copied);
                  },
                ),
                _SettingsTile(
                  emoji: '\u{1F54A}\uFE0F',
                  label: t.aboutUs,
                  onTap: () => open(const AboutScreen()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.c(0xFFFFF9EE), Palette.c(0xFFF4E6CE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.c(0xFFD6C5A9), width: 1.0),
          boxShadow: const [
            BoxShadow(color: Color(0x122C2523), blurRadius: 4, offset: Offset(0, 1.5)),
          ],
        ),
        child: Icon(icon, size: 20, color: Palette.c(0xFFB87B28)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Palette.c(0xFFF7ECDA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.c(0xFFC48B36), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x102C2523), blurRadius: 4, offset: Offset(0, 1.5)),
              ],
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Palette.c(0xFF261D16),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Palette.c(0xFFB87B28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FontSizeSettingTile extends StatelessWidget {
  final int percent;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _FontSizeSettingTile({
    required this.percent,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.c(0xFFF7ECDA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.c(0xFFC48B36), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x102C2523), blurRadius: 4, offset: Offset(0, 1.5)),
          ],
        ),
        child: Row(
          children: [
            const Text('🔤', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Font Size',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Palette.c(0xFF261D16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scripture text · $percent%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: Palette.c(0xFF705D49),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Palette.c(0xFFFFF9EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Palette.c(0xFFC48B36).withValues(alpha: 0.6),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x102C2523), blurRadius: 4, offset: Offset(0, 1.5)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FontScaleButton(label: 'A-', onTap: onDecrease),
                  const SizedBox(width: 3),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Palette.c(0xFFD6C5A9),
                  ),
                  const SizedBox(width: 3),
                  _FontScaleButton(label: 'A+', onTap: onIncrease),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontScaleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FontScaleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: enabled
                ? Palette.c(0xFF261D16)
                : Palette.c(0xFF705D49).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _QuickPickerResult {
  final BookModel book;
  final int chapter;
  final int verse;

  const _QuickPickerResult(this.book, this.chapter, [this.verse = 0]);
}

class _QuickPickerSheet extends StatefulWidget {
  final ReaderLanguage primaryLanguage;
  final BookModel initialBook;
  final int initialChapter;
  final int initialVerse;
  final PickerStep initialStep;

  const _QuickPickerSheet({
    required this.primaryLanguage,
    required this.initialBook,
    required this.initialChapter,
    this.initialVerse = 0,
    this.initialStep = PickerStep.book,
  });

  @override
  State<_QuickPickerSheet> createState() => _QuickPickerSheetState();
}

class _QuickPickerSheetState extends State<_QuickPickerSheet> {
  late PickerStep _step = PickerStep.book;
  int _sheetChapter = 0;
  /// Verses in the chosen chapter, read from a built-in table: the grid is
  /// painted at once, never waits on the database and can never be blank.
  int get _verseCount {
    final int n = verseCountOf(MockBible.books.indexOf(_book) + 1, _sheetChapter);
    return n > 0 ? n : 31;
  }

  int? _tappedCell;
  Timer? _flashTimer;

  late Testament _testament;
  late BookModel _book = widget.initialBook;
  final ScrollController _bookScrollController = ScrollController();
  bool _autoScrolled = false;

  static const double _bookTileHeight = 50.0;
  static const double _bookTileGutter = 8.0;
  static const double _bookListInset = 16.0;
  static const double _bookRowExtent = _bookTileHeight + _bookTileGutter;

  @override
  void initState() {
    super.initState();
    _testament = MockBible.oldTestament.contains(widget.initialBook)
        ? Testament.oldTestament
        : Testament.newTestament;

    // Re-entry from Android back opens the sheet on the verse step, so seed the
    // step and the chapter whose verses it shows.
    _step = widget.initialStep;
    if (widget.initialStep == PickerStep.verse) {
      _sheetChapter = widget.initialChapter;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentBook());
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _bookScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentBook() {
    if (!mounted || _autoScrolled) return;
    if (!_bookScrollController.hasClients) return;
    _autoScrolled = true;

    final ScrollPosition position = _bookScrollController.position;
    final int index =
        _books.indexWhere((b) => b.bibleId == widget.initialBook.bibleId);

    _bookScrollController.animateTo(
      index < 0 ? 0.0 : _centreOffsetFor(index, position),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  double _centreOffsetFor(int index, ScrollPosition position) {
    final double rowCentre =
        _bookListInset + (index * _bookRowExtent) + (_bookTileHeight / 2);
    final double raw = rowCentre - (position.viewportDimension / 2);
    return raw.clamp(0.0, position.maxScrollExtent);
  }

  List<BookModel> get _books => _testament == Testament.oldTestament
      ? MockBible.oldTestament
      : MockBible.newTestament;

  String get _selectBookLabel {
    switch (widget.primaryLanguage) {
      case ReaderLanguage.english:
        return 'Select Book';
      case ReaderLanguage.telugu:
        return 'పుస్తకం ఎంచుకోండి';
      case ReaderLanguage.hindi:
        return 'पुस्तक चुनें';
    }
  }

  String get _selectChapterLabel {
    final name = _book.nameFor(widget.primaryLanguage);
    switch (widget.primaryLanguage) {
      case ReaderLanguage.english:
        return 'Select Chapter — $name';
      case ReaderLanguage.telugu:
        return 'అధ్యాయం ఎంచుకోండి — $name';
      case ReaderLanguage.hindi:
        return 'अध्याय चुनें — $name';
    }
  }

  String get _selectVerseLabel {
    final name = _book.nameFor(widget.primaryLanguage);
    switch (widget.primaryLanguage) {
      case ReaderLanguage.english:
        return 'Select Verse — $name $_sheetChapter';
      case ReaderLanguage.telugu:
        return 'వచనం ఎంచుకోండి — $name $_sheetChapter';
      case ReaderLanguage.hindi:
        return 'वचन चुनें — $name $_sheetChapter';
    }
  }

  String get _oldTestamentLabel {
    switch (widget.primaryLanguage) {
      case ReaderLanguage.english:
        return 'Old Testament';
      case ReaderLanguage.telugu:
        return 'పాత నిబంధన';
      case ReaderLanguage.hindi:
        return 'पुराना नियम';
    }
  }

  String get _newTestamentLabel {
    switch (widget.primaryLanguage) {
      case ReaderLanguage.english:
        return 'New Testament';
      case ReaderLanguage.telugu:
        return 'క్రొత్త నిబంధన';
      case ReaderLanguage.hindi:
        return 'नया नियम';
    }
  }

  String _chapterCountLabel(int count) {
    switch (widget.primaryLanguage) {
      case ReaderLanguage.english:
        return '$count ch';
      case ReaderLanguage.telugu:
        return '$count అధ్యా.';
      case ReaderLanguage.hindi:
        return '$count अध्य.';
    }
  }

  void _flashNumberCell(int number, VoidCallback action) {
    if (_flashTimer != null) return;
    setState(() => _tappedCell = number);
    _flashTimer = Timer(const Duration(milliseconds: 140), () {
      _flashTimer = null;
      if (mounted) action();
    });
  }

  void _openChapters(int chapter) {
    _flashNumberCell(chapter, () {
      setState(() {
        _sheetChapter = chapter;
        // The chapter tile that was just flashed must not carry over: the verse
        // grid always opens clean, with nothing selected.
        _tappedCell = null;
        _step = PickerStep.verse;
      });
    });
  }

  void _stepBack() {
    _flashTimer?.cancel();
    _flashTimer = null;
    setState(() => _tappedCell = null);

    switch (_step) {
      case PickerStep.verse:
        setState(() => _step = PickerStep.chapter);
      case PickerStep.chapter:
        setState(() => _step = PickerStep.book);
      case PickerStep.book:
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == PickerStep.book,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _stepBack();
      },
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.c(0xFFCDAF85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _stepBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _step == PickerStep.verse
                              ? _selectVerseLabel
                              : _step == PickerStep.chapter
                                  ? _selectChapterLabel
                                  : _selectBookLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (_step == PickerStep.book) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTestamentToggleItem(
                          label: _oldTestamentLabel,
                          selected: _testament == Testament.oldTestament,
                          onTap: () => setState(() {
                            _testament = Testament.oldTestament;
                            _autoScrolled = false;
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => _scrollToCurrentBook());
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTestamentToggleItem(
                          label: _newTestamentLabel,
                          selected: _testament == Testament.newTestament,
                          onTap: () => setState(() {
                            _testament = Testament.newTestament;
                            _autoScrolled = false;
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => _scrollToCurrentBook());
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _bookScrollController,
                    padding: const EdgeInsets.all(_bookListInset),
                    itemExtent: _bookRowExtent,
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final BookModel book = _books[index];
                      return _buildBookTile(
                        book,
                        active: book.bibleId == widget.initialBook.bibleId,
                      );
                    },
                  ),
                ),
              ],
              if (_step == PickerStep.chapter)
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _book.chapterCount,
                    itemBuilder: (context, index) {
                      final chapter = index + 1;
                      final bool active = _book.bibleId == widget.initialBook.bibleId &&
                          chapter == widget.initialChapter;
                      final bool flash = _tappedCell == chapter;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openChapters(chapter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          alignment: Alignment.center,
                          decoration: flash
                              ? BoxDecoration(
                                  color: Palette.c(0xFFC88A2E),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x102C2523), blurRadius: 4, offset: Offset(0, 1.5)),
                                  ],
                                )
                              : active
                                  ? _kActivePillDeco
                                  : _kParchmentPillDeco,
                          child: Text(
                            '$chapter',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: flash
                                  ? Palette.c(0xFFFFFFFF)
                                  : active
                                      ? Palette.c(0xFF4A2800)
                                      : Palette.c(0xFF261D16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_step == PickerStep.verse)
                Expanded(
                  child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: _verseCount,
                          itemBuilder: (context, index) {
                            final verse = index + 1;
                            final bool flash = _tappedCell == verse;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _flashNumberCell(verse, () {
                                Navigator.of(context).pop(
                                  _QuickPickerResult(_book, _sheetChapter, verse),
                                );
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                alignment: Alignment.center,
                                decoration: flash
                                    ? BoxDecoration(
                                        color: Palette.c(0xFFC88A2E),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x102C2523), blurRadius: 4, offset: Offset(0, 1.5)),
                                        ],
                                      )
                                    : _kParchmentPillDeco,
                                child: Text(
                                  '$verse',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: flash
                                        ? Palette.c(0xFFFFFFFF)
                                        : Palette.c(0xFF261D16),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookTile(BookModel book, {required bool active}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _book = book;
            _step = PickerStep.chapter;
          });
        },
        child: Container(
          height: _bookTileHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: active ? _kActivePillDeco : _kParchmentPillDeco,
          child: Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: active ? Palette.c(0xFFC88A2E) : Palette.c(0xFFB87B28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  book.nameFor(widget.primaryLanguage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 15,
                    color: active ? Palette.c(0xFF4A2800) : Palette.c(0xFF261D16),
                  ),
                ),
              ),
              Text(
                _chapterCountLabel(book.chapterCount),
                style: TextStyle(
                  color: active ? Palette.c(0xFF4A2800) : Palette.c(0xFF8C7358),
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: active ? Palette.c(0xFFC88A2E) : Palette.c(0xFFB87B28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestamentToggleItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Palette.c(0xFFC88A2E) : null,
          gradient: selected
              ? null
              : LinearGradient(
                  colors: [Palette.c(0xFFFFF9ED), Palette.c(0xFFF1E5CF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? null
              : Border.all(color: Palette.c(0xFFD6C5A9), width: 1.0),
          boxShadow: selected ? AppElevation.card : AppElevation.cream,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Palette.c(0xFFFFFFFF) : Palette.c(0xFF261D16),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}