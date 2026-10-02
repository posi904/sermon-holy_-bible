import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/reader_session.dart';
import '../core/services/study_db_service.dart';
import '../core/theme/app_theme.dart';

/// Shared page frame of the study screens: themed canvas + slim app bar.
class _StudyScaffold extends StatelessWidget {
  const _StudyScaffold({
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ReaderPalette.canvas,
      appBar: AppBar(
        backgroundColor: ReaderPalette.canvas,
        foregroundColor: ReaderPalette.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ReaderPalette.ink,
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _StudyMessage extends StatelessWidget {
  const _StudyMessage(this.message, {this.onRetry, this.retryLabel = ''});

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, height: 1.5, color: ReaderPalette.inkSoft),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens [bookId] [chapter] (and [verse] when > 0) in the Bible reader and
/// closes the study screen that was on top of it.
void _openInReader(BuildContext context, int bookId, int chapter, int verse) {
  final NavigatorState nav = Navigator.of(context);
  nav.pop();
  ReaderSession.instance.openPassage(ScriptureJump(
    bookId: bookId,
    chapter: chapter,
    verseStart: verse,
  ));
}

// ---------------------------------------------------------------- saved verses

/// Bookmarks or Favorites (by [kind]): every saved verse, newest first. One
/// tap opens the reader on that exact verse; the trash icon removes it at once.
class SavedVersesScreen extends StatefulWidget {
  const SavedVersesScreen({super.key, required this.kind});

  final String kind;

  @override
  State<SavedVersesScreen> createState() => _SavedVersesScreenState();
}

class _SavedVersesScreenState extends State<SavedVersesScreen> {
  List<SavedVerse>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _items = null;
    });
    try {
      final List<SavedVerse> rows =
          await StudyDbService.instance.listSaved(widget.kind);
      if (mounted) setState(() => _items = rows);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _remove(SavedVerse item) async {
    final List<SavedVerse> items = _items ?? <SavedVerse>[];
    final int index = items.indexOf(item);
    if (index < 0) return;
    // Gone from the list and from the verse cards at once; SQLite follows.
    setState(() => _items = List<SavedVerse>.of(items)..removeAt(index));
    StudyStore.instance
        .forget(widget.kind, item.bookId, item.chapter, item.verse);
    try {
      await StudyDbService.instance.removeSaved(widget.kind,
          bookId: item.bookId, chapter: item.chapter, verse: item.verse);
    } catch (_) {
      StudyStore.instance
          .remember(widget.kind, item.bookId, item.chapter, item.verse);
      if (mounted) unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ReaderSession.instance.language,
      builder: (BuildContext context, String lang, Widget? child) {
        final AppText t = AppText.of(lang);
        final bool bookmarks = widget.kind == StudyDbService.kBookmark;
        final List<SavedVerse>? items = _items;
        final Widget body;
        if (_failed) {
          body = _StudyMessage(t.loadFailed, onRetry: _load, retryLabel: t.retry);
        } else if (items == null) {
          body = const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        } else if (items.isEmpty) {
          body = _StudyMessage(bookmarks ? t.noBookmarks : t.noFavorites);
        } else {
          body = ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: items.length,
            separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 8),
            itemBuilder: (BuildContext c, int i) => _SavedVerseTile(
              item: items[i],
              lang: lang,
              removeTooltip: t.remove,
              onOpen: () => _openInReader(
                  context, items[i].bookId, items[i].chapter, items[i].verse),
              onRemove: () => _remove(items[i]),
            ),
          );
        }
        return _StudyScaffold(
          title: bookmarks ? t.bookmarks : t.favorites,
          body: body,
        );
      },
    );
  }
}

class _SavedVerseTile extends StatelessWidget {
  const _SavedVerseTile({
    required this.item,
    required this.lang,
    required this.removeTooltip,
    required this.onOpen,
    required this.onRemove,
  });

  final SavedVerse item;
  final String lang;
  final String removeTooltip;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String reference =
        '${localizedBookName(item.bookId, lang)} ${item.chapter}:${item.verse}';
    return Material(
      color: ReaderPalette.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ReaderPalette.cardBorder, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reference,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ReaderPalette.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.textFor(lang),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: ReaderPalette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: removeTooltip,
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: ReaderPalette.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ reading history

/// Chapters read, newest first, grouped by day. One tap reopens a chapter.
class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  List<ReadingEntry>? _entries;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _entries = null;
    });
    try {
      final List<ReadingEntry> rows = await StudyDbService.instance.history();
      if (mounted) setState(() => _entries = rows);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _confirmClear(AppText t) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(t.clearHistoryQuestion),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(t.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.clearHistory)),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _entries = <ReadingEntry>[]);
    try {
      await StudyDbService.instance.clearHistory();
    } catch (_) {
      if (mounted) unawaited(_load());
    }
  }

  String _dayLabel(AppText t, DateTime day) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime d = DateTime(day.year, day.month, day.day);
    final int diff = today.difference(d).inDays;
    if (diff == 0) return t.today;
    if (diff == 1) return t.yesterday;
    return t.formatDate(d);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ReaderSession.instance.language,
      builder: (BuildContext context, String lang, Widget? child) {
        final AppText t = AppText.of(lang);
        final List<ReadingEntry>? entries = _entries;
        final Widget body;
        if (_failed) {
          body = _StudyMessage(t.loadFailed, onRetry: _load, retryLabel: t.retry);
        } else if (entries == null) {
          body = const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        } else if (entries.isEmpty) {
          body = _StudyMessage(t.noHistory);
        } else {
          // Flatten into day headers (String) and entries.
          final List<Object> rows = <Object>[];
          DateTime? lastDay;
          for (final ReadingEntry e in entries) {
            final DateTime d = DateTime(e.when.year, e.when.month, e.when.day);
            if (lastDay == null || d != lastDay) {
              rows.add(_dayLabel(t, d));
              lastDay = d;
            }
            rows.add(e);
          }
          body = ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: rows.length,
            itemBuilder: (BuildContext c, int i) {
              final Object row = rows[i];
              if (row is String) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                  child: Text(
                    row.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: ReaderPalette.inkSoft,
                    ),
                  ),
                );
              }
              final ReadingEntry e = row as ReadingEntry;
              final String name = localizedBookName(e.bookId, lang);
              final String title = e.verse > 0
                  ? '$name ${e.chapter}:${e.verse}'
                  : '$name ${e.chapter}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: ReaderPalette.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        _openInReader(context, e.bookId, e.chapter, e.verse),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: ReaderPalette.cardBorder, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 18, color: ReaderPalette.gold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ReaderPalette.ink,
                              ),
                            ),
                          ),
                          Text(
                            t.formatTime(e.when),
                            style: TextStyle(
                                fontSize: 12.5, color: ReaderPalette.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        final bool hasRows = entries != null && entries.isNotEmpty;
        return _StudyScaffold(
          title: t.readingHistory,
          actions: [
            if (hasRows)
              IconButton(
                tooltip: t.clearHistory,
                onPressed: () => _confirmClear(t),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
          ],
          body: body,
        );
      },
    );
  }
}
