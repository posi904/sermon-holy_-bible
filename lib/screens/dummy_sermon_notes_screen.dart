import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n.dart';
import '../core/mock_data.dart';
import '../core/reader_session.dart';
import '../core/services/bible_db_service.dart';
import '../core/services/sermon_db_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/reader_theme.dart';
import '../core/verse_counts.dart';

/// Sermon Notes — a live-service companion.
///
/// Everything auto-saves to SQLite (700 ms after the last edit, when the app is
/// backgrounded, and when leaving the screen), so a note is never lost — with
/// no banners or dialogs, only a quiet status line.
///
/// The interface follows the Bible Reader's primary language (Telugu, English
/// or Hindi) and every scripture reference is a live link that opens that
/// exact verse in the reader.
class DummySermonNotesScreen extends StatefulWidget {
  const DummySermonNotesScreen({super.key});

  @override
  State<DummySermonNotesScreen> createState() => _DummySermonNotesScreenState();
}

class _DummySermonNotesScreenState extends State<DummySermonNotesScreen>
    with WidgetsBindingObserver {
  static const List<String> _services = [
    'Sunday Service',
    'Fasting Prayer',
    'Youth Fellowship',
    'Mid-week Service',
  ];

  final TextEditingController _title = TextEditingController();
  final TextEditingController _preacher = TextEditingController();
  final TextEditingController _customService = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _pointInput = TextEditingController();
  final FocusNode _pointFocus = FocusNode();

  int? _id;
  String _service = _services.first;
  bool _customMode = false;
  DateTime _date = DateTime.now();
  final List<String> _points = <String>[];
  final List<SermonRef> _refs = <SermonRef>[];

  Timer? _debounce;
  bool _dirty = false;
  bool _saveFailed = false;
  bool _justSaved = false;
  Timer? _savedFlash;
  int _saveRetries = 0;
  Future<void> _saveChain = Future<void>.value();

  /// Strings in the reader's current primary language.
  AppText get _t => AppText.of(ReaderSession.instance.language.value);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreLatest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _savedFlash?.cancel();
    // Final flush: snapshot NOW (controllers are disposed right after), then
    // write after any in-flight save so ordering is preserved.
    if (_dirty) {
      final SermonRecord rec = _snapshot();
      if (!(rec.isBlank && _id == null)) {
        _saveChain = _saveChain.then((_) async {
          try {
            await SermonDbService.instance.save(rec);
          } catch (_) {}
        });
      }
    }
    _title.dispose();
    _preacher.dispose();
    _customService.dispose();
    _body.dispose();
    _pointInput.dispose();
    _pointFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _debounce?.cancel();
      _saveNow();
    }
  }

  // ---------------------------------------------------------------- persistence

  String get _serviceName =>
      _customMode ? _customService.text.trim() : _service;

  SermonRecord _snapshot() => SermonRecord(
        id: _id,
        title: _title.text.trim(),
        preacher: _preacher.text.trim(),
        service: _serviceName,
        date: _date,
        points: List<String>.of(_points),
        refs: List<SermonRef>.of(_refs),
        body: _body.text,
        updatedAt: DateTime.now(),
      );

  void _markDirty() {
    final bool was = _dirty;
    _dirty = true;
    if (!was && mounted) setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  /// Serialised so two overlapping saves can never insert a duplicate row.
  Future<void> _saveNow() {
    _saveChain = _saveChain.then((_) => _doSave());
    return _saveChain;
  }

  Future<void> _doSave() async {
    if (!_dirty) return;
    final SermonRecord rec = _snapshot();
    if (rec.isBlank && _id == null) {
      _dirty = false;
      if (mounted) setState(() {});
      return;
    }
    _dirty = false;
    try {
      _id = await SermonDbService.instance.save(rec);
      _saveRetries = 0;
      if (mounted) setState(() => _saveFailed = false);
    } catch (_) {
      _dirty = true;
      if (mounted) setState(() => _saveFailed = true);
      // Quietly try again a few times; the note stays in memory meanwhile.
      if (_saveRetries < 6) {
        _saveRetries++;
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 3), _saveNow);
      }
    }
  }

  Future<void> _restoreLatest() async {
    try {
      final SermonRecord? latest = await SermonDbService.instance.lastEdited();
      if (!mounted || latest == null || _dirty || _id != null) return;
      _fill(latest);
    } catch (_) {
      // First launch or unavailable DB: start with an empty note.
    }
  }

  void _fill(SermonRecord r) {
    setState(() {
      _id = r.id;
      _title.text = r.title;
      _preacher.text = r.preacher;
      _body.text = r.body;
      _date = r.date;
      _points
        ..clear()
        ..addAll(r.points);
      _refs
        ..clear()
        ..addAll(r.refs);
      if (_services.contains(r.service)) {
        _customMode = false;
        _service = r.service;
        _customService.clear();
      } else if (r.service.isEmpty) {
        _customMode = false;
        _service = _services.first;
      } else {
        _customMode = true;
        _customService.text = r.service;
      }
      _dirty = false;
      _saveFailed = false;
    });
  }

  Future<void> _newNote() async {
    _debounce?.cancel();
    await _saveNow();
    if (!mounted) return;
    _clearNote();
  }

  /// Empties the notepad into a fresh, unsaved note (nothing is written).
  void _clearNote() {
    _debounce?.cancel();
    setState(() {
      _id = null;
      _title.clear();
      _preacher.clear();
      _body.clear();
      _customService.clear();
      _customMode = false;
      _service = _services.first;
      _date = DateTime.now();
      _points.clear();
      _refs.clear();
      _dirty = false;
      _saveFailed = false;
    });
  }

  Future<void> _openSaved() async {
    _debounce?.cancel();
    await _saveNow();
    if (!mounted) return;
    final SermonRecord? picked = await showModalBottomSheet<SermonRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ReaderPalette.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SavedSermonsSheet(
        currentId: _id,
        text: _t,
        onDeleted: _onSermonDeleted,
      ),
    );
    if (picked != null && mounted) _fill(picked);
  }

  /// The sheet deleted a note. If it is the one open in the notepad, the
  /// notepad starts a fresh note straight away (and can never resurrect it).
  void _onSermonDeleted(int id) {
    if (!mounted || id != _id) return;
    _clearNote();
  }

  /// "Save": folds in any half-typed point, writes the note NOW, lowers the
  /// keyboard and confirms quietly on the button itself (no banner or pop-up).
  Future<void> _saveAndFinish() async {
    if (_pointInput.text.trim().isNotEmpty) _addPoint();
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    await _saveNow();
    if (!mounted || _saveFailed) return;
    _savedFlash?.cancel();
    setState(() => _justSaved = true);
    _savedFlash = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _justSaved = false);
    });
  }

  // ------------------------------------------------------------------ actions

  void _addPoint([String? raw]) {
    final String text = (raw ?? _pointInput.text).trim();
    if (text.isEmpty) return;
    setState(() => _points.add(text));
    _pointInput.clear();
    _pointFocus.requestFocus(); // keep the keyboard up for the next point
    _markDirty();
  }

  Future<void> _addReference() async {
    final SermonRef? ref = await showModalBottomSheet<SermonRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ReaderPalette.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddReferenceSheet(text: _t),
    );
    if (ref == null || !mounted) return;
    setState(() => _refs.add(ref));
    _markDirty();
  }

  /// Tapping a reference opens that exact verse in the Bible reader. The note
  /// is flushed to disk first, and the reader's back gesture returns here.
  void _openRef(SermonRef r) {
    if (!r.canOpen) {
      _previewRef(r);
      return;
    }
    _debounce?.cancel();
    unawaited(_saveNow());
    ReaderSession.instance.openPassage(ScriptureJump(
      bookId: r.bookId,
      chapter: r.chapter,
      verseStart: r.verseStart,
      verseEnd: r.verseEnd,
      fromNotes: true,
    ));
  }

  void _previewRef(SermonRef r) {
    final String lang = _t.lang;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ReaderPalette.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.label(lang),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ReaderPalette.gold)),
            const SizedBox(height: 10),
            Text(
              r.text.isEmpty ? _t.verseTextMissing : r.text,
              style: TextStyle(
                  fontSize: 16, height: 1.6, color: ReaderPalette.ink),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) {
      setState(() => _date = d);
      _markDirty();
    }
  }

  // --------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    // Rebuilds whenever the reader's primary language changes, so labels,
    // hints, dates and reference names always match what the believer reads.
    return ValueListenableBuilder<String>(
      valueListenable: ReaderSession.instance.language,
      builder: (BuildContext context, String lang, Widget? _) {
        return Scaffold(
          backgroundColor: ReaderPalette.canvas,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    children: [
                      _buildDetailsCard(),
                      const SizedBox(height: 10),
                      if (_points.isNotEmpty) ...[
                        _buildPointsCard(),
                        const SizedBox(height: 10),
                      ],
                      _buildRefsCard(),
                      const SizedBox(height: 10),
                      _buildNotesCard(),
                    ],
                  ),
                ),
                _buildQuickCaptureBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final AppText t = _t;
    final String status = _saveFailed
        ? t.statusFailed
        : (_dirty ? t.statusSaving : t.statusSaved);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.notesTitle,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ReaderPalette.ink)),
                Text(status,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: _saveFailed
                            ? Palette.c(0xFF9A4B32)
                            : ReaderPalette.inkSoft)),
              ],
            ),
          ),
          Tooltip(
            message: t.saveNoteTip,
            child: Material(
              color: Palette.c(0xFFF7E6C4),
              shape: StadiumBorder(
                  side: BorderSide(color: ReaderPalette.gold, width: 1.4)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: _saveAndFinish,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          _justSaved
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded,
                          size: 17,
                          color: ReaderPalette.gold),
                      const SizedBox(width: 5),
                      Text(_justSaved ? t.savedNow : t.saveNote,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Palette.c(0xFF4A2800))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: t.savedSermons,
            icon: Icon(Icons.history_rounded, color: ReaderPalette.gold),
            onPressed: _openSaved,
          ),
          IconButton(
            tooltip: t.newSermon,
            icon: Icon(Icons.note_add_outlined, color: ReaderPalette.gold),
            onPressed: _newNote,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    String? label,
    Widget? trailing,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: ReaderPalette.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ReaderPalette.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 0 : 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: ReaderPalette.inkSoft)),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }

  InputDecoration _fieldDeco(String hint, {IconData? icon}) => InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: ReaderPalette.inkSoft.withValues(alpha: 0.6)),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: ReaderPalette.gold),
        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
      );

  Widget _buildDetailsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _markDirty(),
            style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: ReaderPalette.ink),
            decoration: _fieldDeco(_t.titleHint),
          ),
          Divider(height: 10, color: ReaderPalette.cardBorder),
          TextField(
            controller: _preacher,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _markDirty(),
            style: TextStyle(fontSize: 15, color: ReaderPalette.ink),
            decoration: _fieldDeco(_t.preacherHint,
                icon: Icons.person_outline_rounded),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final String s in _services)
                _serviceChip(_t.serviceLabel(s), !_customMode && _service == s, () {
                  setState(() {
                    _customMode = false;
                    _service = s;
                  });
                  _markDirty();
                }),
              _serviceChip(_t.serviceOther, _customMode, () {
                setState(() => _customMode = true);
                _markDirty();
              }),
            ],
          ),
          if (_customMode)
            TextField(
              controller: _customService,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _markDirty(),
              style: TextStyle(fontSize: 15, color: ReaderPalette.ink),
              decoration:
                  _fieldDeco(_t.serviceNameHint, icon: Icons.church_outlined),
            ),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _pickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: ReaderPalette.gold),
                  const SizedBox(width: 8),
                  Text(_t.formatDate(_date),
                      style: TextStyle(
                          fontSize: 14, color: ReaderPalette.inkSoft)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? ReaderPalette.ink : ReaderPalette.inkSoft,
      ),
      backgroundColor: ReaderPalette.canvas,
      selectedColor: ReaderPalette.chipSelected,
      side: BorderSide(
        color: selected ? ReaderPalette.pulseBorder : ReaderPalette.cardBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPointsCard() {
    return _card(
      label: _t.pointsLabel,
      child: Column(
              children: [
                for (int i = 0; i < _points.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                              color: ReaderPalette.medallion,
                              shape: BoxShape.circle),
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: ReaderPalette.medallionInk)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_points[i],
                              style: TextStyle(
                                  fontSize: 15.5,
                                  height: 1.45,
                                  color: ReaderPalette.ink)),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _points.removeAt(i));
                            _markDirty();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded,
                                size: 17, color: ReaderPalette.inkSoft),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRefsCard() {
    return _card(
      label: _t.refsLabel,
      compact: _refs.isEmpty,
      trailing: TextButton.icon(
        onPressed: _addReference,
        icon: Icon(Icons.add_rounded, size: 18, color: ReaderPalette.gold),
        label: Text(_t.add,
            style: TextStyle(
                color: ReaderPalette.gold, fontWeight: FontWeight.w700)),
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: _refs.isEmpty
          ? const SizedBox.shrink()
          : Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (int i = 0; i < _refs.length; i++)
                  GestureDetector(
                    // Long-press peeks at the saved verse text without leaving
                    // the note; a tap opens the verse in the Bible reader.
                    onLongPress: () => _previewRef(_refs[i]),
                    child: InputChip(
                      avatar: Icon(Icons.menu_book_rounded,
                          size: 15, color: ReaderPalette.gold),
                      label: Text(_refs[i].label(_t.lang),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ReaderPalette.ink)),
                      tooltip: _t.openInBible,
                      backgroundColor: ReaderPalette.canvas,
                      side: BorderSide(color: ReaderPalette.cardBorder),
                      deleteIconColor: ReaderPalette.inkSoft,
                      onPressed: () => _openRef(_refs[i]),
                      onDeleted: () {
                        setState(() => _refs.removeAt(i));
                        _markDirty();
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildNotesCard() {
    return _card(
      label: _t.notesLabel,
      child: TextField(
        controller: _body,
        maxLines: null,
        minLines: 6,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        onChanged: (_) => _markDirty(),
        style: TextStyle(
            fontSize: 16, height: 1.6, color: ReaderPalette.ink),
        decoration: _fieldDeco(_t.notesHint),
      ),
    );
  }

  /// One labelled capture button: icon over a short word, so nobody has to
  /// guess what a bare "+" does.
  Widget _captureButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    required bool strong,
  }) {
    final Color ink = Palette.c(0xFF4A2800);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: strong ? Palette.c(0xFFF7E6C4) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: strong
                    ? ReaderPalette.gold
                    : ReaderPalette.gold.withValues(alpha: 0.55),
                width: strong ? 1.6 : 1.1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: strong ? ink : ReaderPalette.gold),
                const SizedBox(height: 1),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: strong ? ink : ReaderPalette.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pinned above the keyboard: type a point and tap "Point" (or press enter);
  /// tap "Verse" to attach a scripture reference. Saving the whole note is the
  /// separate "Save" button in the header.
  Widget _buildQuickCaptureBar() {
    final AppText t = _t;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
      decoration: BoxDecoration(
        color: ReaderPalette.card,
        border: Border(top: BorderSide(color: ReaderPalette.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _pointInput,
              focusNode: _pointFocus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: _addPoint,
              style: TextStyle(fontSize: 15, color: ReaderPalette.ink),
              decoration: _fieldDeco(t.pointHint),
            ),
          ),
          const SizedBox(width: 8),
          _captureButton(
            icon: Icons.playlist_add_rounded,
            label: t.addPointLabel,
            tooltip: t.addPointTipFull,
            onTap: _addPoint,
            strong: true,
          ),
          const SizedBox(width: 6),
          _captureButton(
            icon: Icons.menu_book_rounded,
            label: t.addVerseLabel,
            tooltip: t.addVerseTipFull,
            onTap: _addReference,
            strong: false,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- add reference

/// Keeps a typed number inside 1..[max]: an edit that would leave the range
/// (or start with 0) is simply refused, so "chapter 899" can never appear in a
/// book that has one chapter.
class _MaxNumberFormatter extends TextInputFormatter {
  _MaxNumberFormatter(this.max);

  final int Function() max;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final int? n = int.tryParse(newValue.text);
    if (n == null || n < 1 || n > max()) return oldValue;
    return newValue;
  }
}

class _AddReferenceSheet extends StatefulWidget {
  final AppText text;
  const _AddReferenceSheet({required this.text});

  @override
  State<_AddReferenceSheet> createState() => _AddReferenceSheetState();
}

class _AddReferenceSheetState extends State<_AddReferenceSheet> {
  /// Remembered across openings: during a sermon the next reference is very
  /// often in the same book as the last one.
  static int _lastBookId = 0;

  late BookModel _book = _lastBookId >= 1 && _lastBookId <= MockBible.books.length
      ? MockBible.books[_lastBookId - 1]
      : MockBible.books.firstWhere(
          (b) => b.englishName == 'John',
          orElse: () => MockBible.books.first,
        );
  final TextEditingController _chapter = TextEditingController();
  final TextEditingController _verse = TextEditingController();
  bool _busy = false;

  AppText get _t => widget.text;

  int get _bookId => MockBible.books.indexOf(_book) + 1;

  int get _maxChapter {
    final int n = chapterCountOf(_bookId);
    return n > 0 ? n : _book.chapterCount;
  }

  /// The chapter typed so far, or null while empty / out of range.
  int? get _chapterValue {
    final int? n = int.tryParse(_chapter.text.trim());
    return (n != null && n >= 1 && n <= _maxChapter) ? n : null;
  }

  bool get _chapterOutOfRange =>
      _chapter.text.trim().isNotEmpty && _chapterValue == null;

  /// Verses in the typed chapter (0 until the chapter is valid).
  int get _maxVerse {
    final int? ch = _chapterValue;
    return ch == null ? 0 : verseCountOf(_bookId, ch);
  }

  /// Parsed verse range, or null when the field is empty. [_verseError] says
  /// why a non-empty field is not acceptable.
  (int, int)? get _verseRange {
    final String spec = _verse.text.trim();
    if (spec.isEmpty) return null;
    final List<String> parts = spec.split('-');
    final int? a = int.tryParse(parts[0].trim());
    final int? b = parts.length == 2 ? int.tryParse(parts[1].trim()) : a;
    if (parts.length > 2 || a == null || b == null || a < 1 || b < a) {
      return null;
    }
    return (a, b);
  }

  String? get _verseError {
    final String spec = _verse.text.trim();
    if (spec.isEmpty) return null;
    final (int, int)? range = _verseRange;
    if (range == null) return _t.errVerseFormat;
    final int max = _maxVerse;
    if (max > 0 && range.$2 > max) return _t.errVerseRange(max);
    return null;
  }

  bool get _canSubmit =>
      !_busy && _chapterValue != null && _verseError == null;

  @override
  void dispose() {
    _chapter.dispose();
    _verse.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final int? ch = _chapterValue;
    if (ch == null || _verseError != null) return;
    final (int, int)? range = _verseRange;
    final int lo = range?.$1 ?? 0;
    final int hi = range?.$2 ?? 0;
    setState(() => _busy = true);

    final int bookId = _bookId;
    String text = '';
    if (range != null) {
      try {
        final rows = await BibleDbService.instance
            .getVerses(bookId: bookId, chapter: ch)
            .timeout(const Duration(milliseconds: 1500));
        text = rows
            .where((r) {
              final int v = (r['verse'] as int?) ?? 0;
              return v >= lo && v <= hi;
            })
            .map((r) => (r['en'] as String?) ?? '')
            .join(' ')
            .trim();
        if (text.length > 400) text = '${text.substring(0, 400)}…';
      } catch (_) {
        // Slow or unavailable engine: the reference is still saved and still
        // opens the verse; only the long-press preview text is skipped.
      }
    }

    final String tail =
        range == null ? '$ch' : (lo == hi ? '$ch:$lo' : '$ch:$lo-$hi');
    if (!mounted) return;
    _lastBookId = bookId;
    Navigator.of(context).pop(SermonRef(
      ref: '${_book.englishName} $tail',
      text: text,
      bookId: bookId,
      chapter: ch,
      verseStart: lo,
      verseEnd: hi,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final AppText t = _t;
    final int maxChapter = _maxChapter;
    final int maxVerse = _maxVerse;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.addRefTitle,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ReaderPalette.ink)),
          const SizedBox(height: 12),
          DropdownButton<BookModel>(
            value: _book,
            isExpanded: true,
            menuMaxHeight: 340,
            dropdownColor: ReaderPalette.card,
            underline: Divider(height: 1, color: ReaderPalette.cardBorder),
            style: TextStyle(fontSize: 16, color: ReaderPalette.ink),
            items: [
              for (int i = 0; i < MockBible.books.length; i++)
                DropdownMenuItem<BookModel>(
                    value: MockBible.books[i],
                    child: Text(localizedBookName(i + 1, t.lang))),
            ],
            onChanged: (b) {
              if (b != null) setState(() => _book = b);
            },
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _chapter,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _MaxNumberFormatter(() => _maxChapter),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: t.chapterField,
                    helperText: t.rangeHint(maxChapter),
                    errorText:
                        _chapterOutOfRange ? t.errChapter(maxChapter) : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _verse,
                  enabled: _chapterValue != null,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_canSubmit) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: t.verseField,
                    helperText: maxVerse > 0
                        ? t.rangeHint(maxVerse)
                        : t.verseFieldHint,
                    errorText: _verseError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ReaderPalette.gold,
                foregroundColor: Palette.c(0xFFFFFFFF),
                disabledBackgroundColor:
                    ReaderPalette.cardBorder.withValues(alpha: 0.6),
                disabledForegroundColor: ReaderPalette.inkSoft,
              ),
              onPressed: _canSubmit ? _submit : null,
              child: Text(_busy ? t.adding : t.addRefButton),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- saved sermons

class _SavedSermonsSheet extends StatefulWidget {
  final int? currentId;
  final AppText text;

  /// Called the moment a note is deleted (before the database finishes), so
  /// the notepad can drop it if it is the note currently open.
  final ValueChanged<int> onDeleted;

  const _SavedSermonsSheet({
    this.currentId,
    required this.text,
    required this.onDeleted,
  });

  @override
  State<_SavedSermonsSheet> createState() => _SavedSermonsSheetState();
}

class _SavedSermonsSheetState extends State<_SavedSermonsSheet> {
  /// The list lives in memory; a delete edits THIS list first, so the row
  /// disappears on the same frame as the confirmation.
  List<SermonRecord>? _items;
  bool _failed = false;

  AppText get _t => widget.text;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<SermonRecord> rows = await SermonDbService.instance.all();
      if (mounted) {
        setState(() {
          _items = rows;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _confirmDelete(SermonRecord r) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ReaderPalette.card,
        title: Text(_t.deleteQuestion),
        content: Text(_t.cannotUndo),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_t.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(_t.delete)),
        ],
      ),
    );
    final int? id = r.id;
    if (yes != true || id == null || !mounted) return;

    // 1. In memory, right now: the row leaves the sheet.
    setState(() {
      _items = <SermonRecord>[
        for (final SermonRecord x in _items ?? const <SermonRecord>[])
          if (x.id != id) x,
      ];
    });
    // 2. The notepad forgets it too if it was open.
    widget.onDeleted(id);
    // 3. SQLite follows; if that fails the list is rebuilt from the database.
    try {
      await SermonDbService.instance.delete(id);
    } catch (_) {
      if (mounted) unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_t.savedSermons,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ReaderPalette.ink)),
            ),
          ),
          Flexible(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    final List<SermonRecord>? items = _items;
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(_t.loadFailed,
            style: TextStyle(color: ReaderPalette.inkSoft)),
      );
    }
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(_t.noSaved, style: TextStyle(color: ReaderPalette.inkSoft)),
      );
    }
    // Chronological log: newest service first, grouped by month.
    final List<Object> rows = <Object>[];
    String? lastMonth;
    for (final SermonRecord r in items) {
      final String month = _t.formatMonth(r.date);
      if (month != lastMonth) {
        rows.add(month);
        lastMonth = month;
      }
      rows.add(r);
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final Object row = rows[i];
        if (row is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Text(row.toUpperCase(),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: ReaderPalette.inkSoft)),
          );
        }
        final SermonRecord r = row as SermonRecord;
        final String sub = [
          if (r.preacher.isNotEmpty) r.preacher,
          if (r.service.isNotEmpty) _t.serviceLabel(r.service),
          _t.formatDate(r.date),
        ].join(' \u2022 ');
        return Material(
          color: r.id == widget.currentId
              ? ReaderPalette.chipSelected
              : ReaderPalette.card,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: ReaderPalette.cardBorder),
            ),
            title: Text(
              r.title.isEmpty ? _t.untitled : r.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: ReaderPalette.ink),
            ),
            subtitle: Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ReaderPalette.inkSoft)),
            trailing: IconButton(
              tooltip: _t.delete,
              icon: Icon(Icons.delete_outline_rounded,
                  color: ReaderPalette.inkSoft),
              onPressed: () => _confirmDelete(r),
            ),
            onTap: () => Navigator.of(context).pop(r),
          ),
        );
      },
    );
  }
}
