import 'package:flutter/foundation.dart';

/// A request to open an exact passage in the Bible reader.
///
/// [verseStart] of 0 means "the whole chapter" (land at the top). A range such
/// as Romans 8:28-30 is expressed with [verseEnd] > [verseStart].
///
/// Every instance is a distinct object, so tapping the same reference twice
/// still re-triggers the jump (a [ValueNotifier] only fires on a changed
/// value, and two instances never compare equal).
class ScriptureJump {
  final int bookId; // canonical 1 (Genesis) … 66 (Revelation)
  final int chapter;
  final int verseStart;
  final int verseEnd;

  /// True when the jump came from Sermon Notes, so the reader's back gesture
  /// can return the believer to the note they were writing.
  final bool fromNotes;

  ScriptureJump({
    required this.bookId,
    required this.chapter,
    this.verseStart = 0,
    int verseEnd = 0,
    this.fromNotes = false,
  }) : verseEnd = verseEnd < verseStart ? verseStart : verseEnd;
}

/// Asks the app shell to show a tab (0 = Bible Reader, 1 = Sermon Notes).
class TabRequest {
  final int index;
  TabRequest(this.index);
}

/// Tiny app-wide rendezvous between the Bible Reader, Sermon Notes and the
/// shell. Deliberately plain [ValueNotifier]s: no package, no boilerplate.
class ReaderSession {
  ReaderSession._();

  static final ReaderSession instance = ReaderSession._();

  /// Primary reading language code: 'te', 'en' or 'hi'. The reader publishes
  /// it; Sermon Notes and the navigation bar follow it.
  final ValueNotifier<String> language = ValueNotifier<String>('te');

  /// Latest passage the reader should open (set by Sermon Notes).
  final ValueNotifier<ScriptureJump?> jump = ValueNotifier<ScriptureJump?>(null);

  /// Latest tab the shell should show.
  final ValueNotifier<TabRequest?> tab = ValueNotifier<TabRequest?>(null);

  /// Set by the reader after it lands on a verse requested from Sermon Notes;
  /// the next back gesture returns to the note. Cleared by any navigation the
  /// reader makes on its own.
  bool returnToNotes = false;

  /// Opens [target] in the reader and brings the reader tab forward.
  void openPassage(ScriptureJump target) {
    jump.value = target;
    tab.value = TabRequest(0);
  }

  /// Brings the Sermon Notes tab forward.
  void showNotes() {
    returnToNotes = false;
    tab.value = TabRequest(1);
  }
}
