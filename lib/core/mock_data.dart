/// Pure in-memory mock data for the dummy UI.
/// No persistence, no database — everything lives in static lists/maps
/// so the widgets can be wired up and demoed immediately.
library;

class VerseModel {
  final String verseNumber;
  final String english;
  final String telugu;
  final String textHindi;

  const VerseModel({
    required this.verseNumber,
    required this.english,
    required this.telugu,
    required this.textHindi,
  });
}

class BookModel {
  final String englishName;
  final String teluguName;
  final String hindiName;
  final int chapterCount;

  const BookModel({
    required this.englishName,
    required this.teluguName,
    required this.hindiName,
    required this.chapterCount,
  });
}

/// Which testament a Bible book belongs to.
enum Testament { oldTestament, newTestament }

/// A tiny mock "Bible" — just enough books/verses to demo the reader UI.
class MockBible {
  MockBible._();

  /// The 39 books of the Old Testament, in canonical order.
  static const List<BookModel> oldTestament = [
    BookModel(englishName: 'Genesis', teluguName: 'ఆదికాండము', hindiName: 'उत्पत्ति', chapterCount: 50),
    BookModel(englishName: 'Exodus', teluguName: 'నిర్గమకాండము', hindiName: 'निर्गमन', chapterCount: 40),
    BookModel(englishName: 'Leviticus', teluguName: 'లేవీయకాండము', hindiName: 'लैव्यव्यवस्था', chapterCount: 27),
    BookModel(englishName: 'Numbers', teluguName: 'సంఖ్యాకాండము', hindiName: 'गिनती', chapterCount: 36),
    BookModel(englishName: 'Deuteronomy', teluguName: 'ద్వితీయోపదేశకాండము', hindiName: 'व्यवस्थाविवरण', chapterCount: 34),
    BookModel(englishName: 'Joshua', teluguName: 'యెహోషువ', hindiName: 'यहोशू', chapterCount: 24),
    BookModel(englishName: 'Judges', teluguName: 'న్యాయాధిపతులు', hindiName: 'न्यायियों', chapterCount: 21),
    BookModel(englishName: 'Ruth', teluguName: 'రూతు', hindiName: 'रूत', chapterCount: 4),
    BookModel(englishName: '1 Samuel', teluguName: 'సమూయేలు మొదటి గ్రంథము', hindiName: '1 शमूएल', chapterCount: 31),
    BookModel(englishName: '2 Samuel', teluguName: 'సమూయేలు రెండవ గ్రంథము', hindiName: '2 शमूएल', chapterCount: 24),
    BookModel(englishName: '1 Kings', teluguName: 'రాజులు మొదటి గ్రంథము', hindiName: '1 राजा', chapterCount: 22),
    BookModel(englishName: '2 Kings', teluguName: 'రాజులు రెండవ గ్రంథము', hindiName: '2 राजा', chapterCount: 25),
    BookModel(englishName: '1 Chronicles', teluguName: 'దినవృత్తాంతములు మొదటి గ్రంథము', hindiName: '1 इतिहास', chapterCount: 29),
    BookModel(englishName: '2 Chronicles', teluguName: 'దినవృత్తాంతములు రెండవ గ్రంథము', hindiName: '2 इतिहास', chapterCount: 36),
    BookModel(englishName: 'Ezra', teluguName: 'ఎజ్రా', hindiName: 'एज्रा', chapterCount: 10),
    BookModel(englishName: 'Nehemiah', teluguName: 'నెహెమ్యా', hindiName: 'नहेम्याह', chapterCount: 13),
    BookModel(englishName: 'Esther', teluguName: 'ఎస్తేరు', hindiName: 'एस्तेर', chapterCount: 10),
    BookModel(englishName: 'Job', teluguName: 'యోబు', hindiName: 'अय्यूब', chapterCount: 42),
    BookModel(englishName: 'Psalms', teluguName: 'కీర్తనలు', hindiName: 'भजन संहिता', chapterCount: 150),
    BookModel(englishName: 'Proverbs', teluguName: 'సామెతలు', hindiName: 'नीतिवचन', chapterCount: 31),
    BookModel(englishName: 'Ecclesiastes', teluguName: 'ప్రసంగి', hindiName: 'सभोपदेशक', chapterCount: 12),
    BookModel(englishName: 'Song of Solomon', teluguName: 'పరమగీతము', hindiName: 'श्रेष्ठगीत', chapterCount: 8),
    BookModel(englishName: 'Isaiah', teluguName: 'యెషయా', hindiName: 'यशायाह', chapterCount: 66),
    BookModel(englishName: 'Jeremiah', teluguName: 'యిర్మీయా', hindiName: 'यिर्मयाह', chapterCount: 52),
    BookModel(englishName: 'Lamentations', teluguName: 'విలాపవాక్యములు', hindiName: 'विलापगीत', chapterCount: 5),
    BookModel(englishName: 'Ezekiel', teluguName: 'యెహెజ్కేలు', hindiName: 'यहेजकेल', chapterCount: 48),
    BookModel(englishName: 'Daniel', teluguName: 'దానియేలు', hindiName: 'दानिय्येल', chapterCount: 12),
    BookModel(englishName: 'Hosea', teluguName: 'హోషేయ', hindiName: 'होशे', chapterCount: 14),
    BookModel(englishName: 'Joel', teluguName: 'యోవేలు', hindiName: 'योएल', chapterCount: 3),
    BookModel(englishName: 'Amos', teluguName: 'ఆమోసు', hindiName: 'आमोस', chapterCount: 9),
    BookModel(englishName: 'Obadiah', teluguName: 'ఓబద్యా', hindiName: 'ओबद्याह', chapterCount: 1),
    BookModel(englishName: 'Jonah', teluguName: 'యోనా', hindiName: 'योना', chapterCount: 4),
    BookModel(englishName: 'Micah', teluguName: 'మీకా', hindiName: 'मीका', chapterCount: 7),
    BookModel(englishName: 'Nahum', teluguName: 'నహూము', hindiName: 'नहूम', chapterCount: 3),
    BookModel(englishName: 'Habakkuk', teluguName: 'హబక్కూకు', hindiName: 'हबक्कूक', chapterCount: 3),
    BookModel(englishName: 'Zephaniah', teluguName: 'జెఫన్యా', hindiName: 'सपन्याह', chapterCount: 3),
    BookModel(englishName: 'Haggai', teluguName: 'హగ్గయి', hindiName: 'हाग्गै', chapterCount: 2),
    BookModel(englishName: 'Zechariah', teluguName: 'జెకర్యా', hindiName: 'जकर्याह', chapterCount: 14),
    BookModel(englishName: 'Malachi', teluguName: 'మలాకీ', hindiName: 'मलाकी', chapterCount: 4),
  ];

  /// The 27 books of the New Testament, in canonical order.
  static const List<BookModel> newTestament = [
    BookModel(englishName: 'Matthew', teluguName: 'మత్తయి', hindiName: 'मत्ती', chapterCount: 28),
    BookModel(englishName: 'Mark', teluguName: 'మార్కు', hindiName: 'मरकुस', chapterCount: 16),
    BookModel(englishName: 'Luke', teluguName: 'లూకా', hindiName: 'लूका', chapterCount: 24),
    BookModel(englishName: 'John', teluguName: 'యోహాను', hindiName: 'यूहन्ना', chapterCount: 21),
    BookModel(englishName: 'Acts', teluguName: 'అపొస్తలుల కార్యములు', hindiName: 'प्रेरितों के काम', chapterCount: 28),
    BookModel(englishName: 'Romans', teluguName: 'రోమీయులకు', hindiName: 'रोमियों', chapterCount: 16),
    BookModel(englishName: '1 Corinthians', teluguName: 'కొరింథీయులకు మొదటి గ్రంథము', hindiName: '1 कुरिन्थियों', chapterCount: 16),
    BookModel(englishName: '2 Corinthians', teluguName: 'కొరింథీయులకు రెండవ గ్రంథము', hindiName: '2 कुरिन्थियों', chapterCount: 13),
    BookModel(englishName: 'Galatians', teluguName: 'గలతీయులకు', hindiName: 'गलातियों', chapterCount: 6),
    BookModel(englishName: 'Ephesians', teluguName: 'ఎఫెసీయులకు', hindiName: 'इफिसियों', chapterCount: 6),
    BookModel(englishName: 'Philippians', teluguName: 'ఫిలిప్పీయులకు', hindiName: 'फिलिप्पियों', chapterCount: 4),
    BookModel(englishName: 'Colossians', teluguName: 'కొలొస్సయులకు', hindiName: 'कुलुस्सियों', chapterCount: 4),
    BookModel(englishName: '1 Thessalonians', teluguName: 'థెస్సలొనీకయులకు మొదటి గ్రంథము', hindiName: '1 थिस्सलुनीकियों', chapterCount: 5),
    BookModel(englishName: '2 Thessalonians', teluguName: 'థెస్సలొనీకయులకు రెండవ గ్రంథము', hindiName: '2 थिस्सलुनीकियों', chapterCount: 3),
    BookModel(englishName: '1 Timothy', teluguName: 'తిమోతికి మొదటి గ్రంథము', hindiName: '1 तीमुथियुस', chapterCount: 6),
    BookModel(englishName: '2 Timothy', teluguName: 'తిమోతికి రెండవ గ్రంథము', hindiName: '2 तीमुथियुस', chapterCount: 4),
    BookModel(englishName: 'Titus', teluguName: 'తీతుకు', hindiName: 'तीतुस', chapterCount: 3),
    BookModel(englishName: 'Philemon', teluguName: 'ఫిలేమోనుకు', hindiName: 'फिलेमोन', chapterCount: 1),
    BookModel(englishName: 'Hebrews', teluguName: 'హెబ్రీయులకు', hindiName: 'इब्रानियों', chapterCount: 13),
    BookModel(englishName: 'James', teluguName: 'యాకోబు', hindiName: 'याकूब', chapterCount: 5),
    BookModel(englishName: '1 Peter', teluguName: 'పేతురు మొదటి గ్రంథము', hindiName: '1 पतरस', chapterCount: 5),
    BookModel(englishName: '2 Peter', teluguName: 'పేతురు రెండవ గ్రంథము', hindiName: '2 पतरस', chapterCount: 3),
    BookModel(englishName: '1 John', teluguName: 'యోహాను మొదటి గ్రంథము', hindiName: '1 यूहन्ना', chapterCount: 5),
    BookModel(englishName: '2 John', teluguName: 'యోహాను రెండవ గ్రంథము', hindiName: '2 यूहन्ना', chapterCount: 1),
    BookModel(englishName: '3 John', teluguName: 'యోహాను మూడవ గ్రంథము', hindiName: '3 यूहन्ना', chapterCount: 1),
    BookModel(englishName: 'Jude', teluguName: 'యూదా', hindiName: 'यहूदा', chapterCount: 1),
    BookModel(englishName: 'Revelation', teluguName: 'ప్రకటన గ్రంథము', hindiName: 'प्रकाशितवाक्य', chapterCount: 22),
  ];

  /// All 66 books in canonical order (Old Testament followed by New).
  static const List<BookModel> books = [
    ...oldTestament,
    ...newTestament,
  ];

}

class MockJournal {
  MockJournal._();

  static const String letterheadChurchName = 'Grace Fellowship Church';
  static const String letterheadSubtitle = 'Sermon Notes & Spiritual Journal';
  static const String sermonTitle = 'Living by Faith';
  static const String serviceLine = 'Sunday Worship Service';
  static const String dateLine = 'Aug 30, 2026';

  static const List<String> keyPoints = [
    'Faith Changes Everything',
    'Trusting God in Every Season',
    'Living as a Light for Others',
  ];

  static const String closingQuote =
      '"The life of faith is not a life of mounting up wings... but a life of walking and not fainting." — Oswald Chambers';
  static const String closingReference = 'Hebrews 11:1';

  static const int streakDays = 7;

  static const List<String> weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  // true = day completed in streak
  static const List<bool> weekCompletion = [
    true,
    true,
    true,
    true,
    true,
    true,
    true,
  ];

  static const List<PrayerRequest> prayers = [
    PrayerRequest(
      title: 'Healing for Mom',
      dateAdded: 'Aug 24',
      answered: true,
    ),
    PrayerRequest(
      title: 'Wisdom for job decision',
      dateAdded: 'Aug 27',
      answered: true,
    ),
    PrayerRequest(
      title: 'Peace for the youth group',
      dateAdded: 'Aug 29',
      answered: false,
    ),
    PrayerRequest(
      title: 'Safe travels for mission trip',
      dateAdded: 'Aug 30',
      answered: false,
    ),
  ];
}

class PrayerRequest {
  final String title;
  final String dateAdded;
  final bool answered;

  const PrayerRequest({
    required this.title,
    required this.dateAdded,
    required this.answered,
  });
}
