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

  /// Returns a stable mock verse count for [chapter] in [book].
  ///
  /// Only John 3 carries real sample verses in this demo, so that chapter
  /// reports the size of [johnChapter3]; every other chapter returns a
  /// deterministic estimate so the verse grid stays stable across runs.
  static int verseCountFor(BookModel book, int chapter) {
    if (book.englishName == 'John' && chapter == 3) {
      return johnChapter3.length;
    }
    final seed = book.englishName.length * 13 + chapter * 7;
    return 16 + (seed % 25); // 16–40 verses
  }

  /// Chapter 3 of John — KJV English + Telugu (Common Language style) + Hindi.
  static const List<VerseModel> johnChapter3 = [
    VerseModel(
      verseNumber: '14',
      english:
          'And as Moses lifted up the serpent in the wilderness, even so must the Son of man be lifted up:',
      telugu:
          'అరణ్యములో మోషే సర్పమును ఎలా పైకెత్తెనో, ఆలాగే మనుష్యకుమారుడు పైకెత్తబడవలెను.',
      textHindi:
          'और जिस प्रकार मूसा ने जंगल में साँप को ऊँचे पर चढ़ाया, उसी प्रकार अवश्य है कि मनुष्य का पुत्र भी ऊँचे पर चढ़ाया जाए;',
    ),
    VerseModel(
      verseNumber: '15',
      english: 'That whosoever believeth in him should not perish, but have eternal life.',
      telugu:
          'ఆయనయందు విశ్వాసముంచు ప్రతివాడును నశింపక నిత్యజీవము పొందునట్లు ఆలాగు జరిగింపవలెను.',
      textHindi:
          'ताकि जो कोई उस पर विश्वास करे, वह नाश न हो, परन्तु अनन्त जीवन पाए।',
    ),
    VerseModel(
      verseNumber: '16',
      english:
          'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
      telugu:
          'దేవుడు లోకమును ఎంతో ప్రేమించెను. కాగా ఆయన తన అద్వితీయకుమారుని దయచేసెను. ఆయనయందు విశ్వాసముంచు ప్రతివాడును నశింపక నిత్యజీవము పొందునట్లు ఆలాగు చేసెను.',
      textHindi:
          'क्योंकि परमेश्वर ने जगत से ऐसा प्रेम रखा कि उसने अपना एकलौता पुत्र दे दिया, ताकि जो कोई उस पर विश्वास करे, वह नाश न हो, परन्तु अनन्त जीवन पाए।',
    ),
    VerseModel(
      verseNumber: '17',
      english:
          'For God sent not his Son into the world to condemn the world; but that the world through him might be saved.',
      telugu:
          'లోకమునకు తీర్పు తీర్చుటకు దేవుడు తన కుమారుని లోకమునకు పంపలేదు గాని, తనద్వారా లోకము రక్షణ పొందుటకే ఆయనను పంపెను.',
      textHindi:
          'क्योंकि परमेश्वर ने अपने पुत्र को जगत में इसलिये नहीं भेजा कि जगत पर दण्ड की आज्ञा दे, परन्तु इसलिये कि जगत उसके द्वारा उद्धार पाए।',
    ),
  ];

  static const String goldenVerseReference = 'John 3:16';
  static const String goldenVerseEnglish =
      '"For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."';
  static const String goldenVerseTelugu =
      '"దేవుడు లోకమును ఎంతో ప్రేమించెను, కాగా ఆయన తన అద్వితీయకుమారుని దయచేసెను..."';
  static const String goldenVerseHindi =
      '"क्योंकि परमेश्वर ने जगत से ऐसा प्रेम रखा कि उसने अपना एकलौता पुत्र दे दिया..."';
}

class ScriptureChip {
  final String englishRef;
  final String teluguRef;
  final String previewEnglish;
  final String previewTelugu;

  const ScriptureChip({
    required this.englishRef,
    required this.teluguRef,
    required this.previewEnglish,
    required this.previewTelugu,
  });
}

class SermonNoteModel {
  final String title;
  final String preacher;
  final String date;
  final String serviceTag;
  final List<String> keyPoints;
  final List<ScriptureChip> chips;

  const SermonNoteModel({
    required this.title,
    required this.preacher,
    required this.date,
    required this.serviceTag,
    required this.keyPoints,
    required this.chips,
  });
}

/// Mock sermon note content mirroring the "Living by Faith" mockup screen.
class MockSermon {
  MockSermon._();

  static const SermonNoteModel note = SermonNoteModel(
    title: 'Living by Faith',
    preacher: 'Dr. Paul',
    date: 'Sun, Aug 30',
    serviceTag: 'Sunday Worship',
    keyPoints: [
      'Faith Changes Everything',
      'Trusting God in Every Season',
      'Living as a Light',
      'Practical Steps for a Faith-Filled Life',
    ],
    chips: [
      ScriptureChip(
        englishRef: 'John 3:16',
        teluguRef: 'యోహాను 3:16',
        previewEnglish:
            'For God so loved the world, that he gave his only begotten Son...',
        previewTelugu: 'దేవుడు లోకమును ఎంతో ప్రేమించెను...',
      ),
      ScriptureChip(
        englishRef: 'Romans 8:28',
        teluguRef: 'రోమీయులకు 8:28',
        previewEnglish:
            'And we know that all things work together for good to them that love God...',
        previewTelugu:
            'దేవుని ప్రేమించువారికి, అనగా ఆయన సంకల్పముచొప్పున పిలువబడినవారికి, మేలుకలుగుటకై సమస్తమును సమకూడి జరుగుచున్నవని యెరుగుదుము...',
      ),
    ],
  );

  static const String bodyText = '''Faith helps us go beyond the present.

Even in trials, God is working for our good (Romans 8:28).

We walk by faith, not by sight (2 Corinthians 5:7).

Practical Steps
• Spend time in God's Word daily
• Pray with a grateful heart
• Trust His plan, even when we don't understand
• Be a light to others''';
}

class PrayerJournalStat {
  final String label;
  final String value;

  const PrayerJournalStat({required this.label, required this.value});
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
  static const int totalPrayers = 12;
  static const int answeredPrayers = 8;

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
