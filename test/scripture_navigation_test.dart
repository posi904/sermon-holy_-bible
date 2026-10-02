// Unit tests for the pieces that make scripture navigation reliable:
// structured sermon references (incl. notes saved by older versions), the
// shared reader session, and the localisation table.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:scripture_sermon_studio/core/l10n.dart';
import 'package:scripture_sermon_studio/core/mock_data.dart';
import 'package:scripture_sermon_studio/core/reader_session.dart';
import 'package:scripture_sermon_studio/core/services/sermon_db_service.dart';

void main() {
  group('SermonRef', () {
    test('a legacy plain-text reference is recovered into a tappable one', () {
      final SermonRef r = SermonRef.fromJson({'ref': 'John 3:16', 'text': 'x'});
      expect(r.canOpen, isTrue);
      expect(r.bookId, 43);
      expect(r.chapter, 3);
      expect(r.verseStart, 16);
      expect(r.verseEnd, 16);
    });

    test('legacy numbered books and ranges parse', () {
      final SermonRef r = SermonRef.fromJson({'ref': '1 Corinthians 13:4-7'});
      expect(r.bookId, 46);
      expect(r.chapter, 13);
      expect(r.verseStart, 4);
      expect(r.verseEnd, 7);
    });

    test('a whole-chapter legacy reference has verseStart 0', () {
      final SermonRef r = SermonRef.fromJson({'ref': 'Psalms 23'});
      expect(r.bookId, 19);
      expect(r.chapter, 23);
      expect(r.verseStart, 0);
    });

    test('unparseable text stays a label and is not openable', () {
      final SermonRef r = SermonRef.fromJson({'ref': 'see the prophets'});
      expect(r.canOpen, isFalse);
      expect(r.label('te'), 'see the prophets');
    });

    test('structured fields survive a JSON round trip', () {
      const SermonRef a = SermonRef(
        ref: 'Romans 8:28-30',
        bookId: 45,
        chapter: 8,
        verseStart: 28,
        verseEnd: 30,
      );
      final SermonRef b = SermonRef.fromJson(
        Map<String, dynamic>.from(jsonDecode(jsonEncode(a.toJson())) as Map),
      );
      expect(b.bookId, 45);
      expect(b.chapter, 8);
      expect(b.verseStart, 28);
      expect(b.verseEnd, 30);
    });

    test('the label follows the reading language', () {
      const SermonRef r = SermonRef(
        ref: 'John 3:16',
        bookId: 43,
        chapter: 3,
        verseStart: 16,
        verseEnd: 16,
      );
      expect(r.label('en'), 'John 3:16');
      expect(r.label('te'), '${MockBible.books[42].teluguName} 3:16');
      expect(r.label('hi'), '${MockBible.books[42].hindiName} 3:16');
    });
  });

  group('ReaderSession', () {
    test('a jump normalises an inverted verse range', () {
      final ScriptureJump j =
          ScriptureJump(bookId: 43, chapter: 3, verseStart: 16, verseEnd: 2);
      expect(j.verseEnd, 16);
    });

    test('openPassage publishes the passage and asks for the reader tab', () {
      final ReaderSession s = ReaderSession.instance;
      int jumps = 0;
      int tabs = 0;
      void onJump() => jumps++;
      void onTab() => tabs++;
      s.jump.addListener(onJump);
      s.tab.addListener(onTab);

      final ScriptureJump j =
          ScriptureJump(bookId: 43, chapter: 3, verseStart: 16);
      s.openPassage(j);
      s.openPassage(ScriptureJump(bookId: 43, chapter: 3, verseStart: 16));

      // Two identical taps are two distinct requests.
      expect(jumps, 2);
      expect(tabs, 2);
      expect(s.tab.value!.index, 0);

      s.showNotes();
      expect(s.tab.value!.index, 1);
      expect(s.returnToNotes, isFalse);

      s.jump.removeListener(onJump);
      s.tab.removeListener(onTab);
    });
  });

  group('AppText', () {
    test('all three languages are fully populated and distinct', () {
      final AppText en = AppText.of('en');
      final AppText te = AppText.of('te');
      final AppText hi = AppText.of('hi');
      for (final AppText t in <AppText>[en, te, hi]) {
        expect(t.notesTitle, isNotEmpty);
        expect(t.saveNote, isNotEmpty);
        expect(t.themeName('midnight'), isNotEmpty);
        expect(t.errChapter(10), contains('10'));
        expect(t.errVerseMissing(31), contains('31'));
        expect(t.serviceLabel('Sunday Service'), isNotEmpty);
      }
      expect(te.notesTitle, isNot(en.notesTitle));
      expect(hi.notesTitle, isNot(en.notesTitle));
      expect(te.notesTitle, isNot(hi.notesTitle));
    });

    test('custom service names are left untouched', () {
      expect(AppText.of('te').serviceLabel('Cottage Meeting'), 'Cottage Meeting');
    });

    test('unknown language falls back to English', () {
      expect(AppText.of('xx').lang, 'en');
    });
  });
}
