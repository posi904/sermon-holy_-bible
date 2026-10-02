import 'mock_data.dart';

/// Canonical book name for [bookId] (1–66) in language [lang] ('en'|'te'|'hi').
String localizedBookName(int bookId, String lang) {
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

/// Every user-facing string of the Sermon Notes companion and the navigation
/// bar, in the three reading languages. One compact, dependency-free table —
/// the reader's primary language picks the column.
class AppText {
  const AppText._(this.lang);

  final String lang;

  static AppText of(String lang) =>
      AppText._(lang == 'te' || lang == 'hi' ? lang : 'en');

  String _t(String en, String te, String hi) =>
      lang == 'te' ? te : (lang == 'hi' ? hi : en);

  // ------------------------------------------------------------ navigation
  String get navReader => _t('Bible Reader', 'బైబిల్ పఠనం', 'बाइबल पठन');
  String get navNotes => _t('Sermon Notes', 'ప్రసంగ నోట్స్', 'प्रवचन नोट्स');

  // ------------------------------------------------------------ header
  String get notesTitle => _t('Sermon Notes', 'ప్రసంగ నోట్స్', 'प्रवचन नोट्स');
  String get statusSaving => _t('Saving…', 'సేవ్ అవుతోంది…', 'सहेज रहा है…');
  String get statusSaved => _t('Saved on this device',
      'ఈ పరికరంలో సేవ్ చేయబడింది', 'इस डिवाइस पर सहेजा गया');
  String get statusFailed => _t('Could not save — retrying',
      'సేవ్ కాలేదు — మళ్లీ ప్రయత్నిస్తోంది', 'सहेज नहीं सका — फिर कोशिश कर रहा है');
  String get savedSermons =>
      _t('Saved sermons', 'సేవ్ చేసిన ప్రసంగాలు', 'सहेजे गए प्रवचन');
  String get newSermon => _t('New sermon', 'కొత్త ప్రసంగం', 'नया प्रवचन');

  // ------------------------------------------------------------ details
  String get titleHint =>
      _t('Sermon title', 'ప్రసంగ శీర్షిక', 'प्रवचन का शीर्षक');
  String get preacherHint => _t('Preacher / Pastor name',
      'బోధకుని / పాస్టర్ పేరు', 'प्रचारक / पास्टर का नाम');
  String get serviceNameHint =>
      _t('Service name', 'ఆరాధన పేరు', 'आराधना का नाम');
  String get serviceOther => _t('Other\u2026', 'ఇతరం\u2026', 'अन्य\u2026');

  /// Localised label for a canonical (English) quick-service key. Unknown /
  /// custom names are returned untouched.
  String serviceLabel(String canonical) {
    switch (canonical) {
      case 'Sunday Service':
        return _t(canonical, 'ఆదివారం ఆరాధన', 'रविवार आराधना');
      case 'Fasting Prayer':
        return _t(canonical, 'ఉపవాస ప్రార్థన', 'उपवास प्रार्थना');
      case 'Youth Fellowship':
        return _t(canonical, 'యువత సహవాసం', 'युवा संगति');
      case 'Mid-week Service':
        return _t(canonical, 'వారం మధ్య ఆరాధన', 'सप्ताह-मध्य आराधना');
      default:
        return canonical;
    }
  }

  // ------------------------------------------------------------ cards
  String get pointsLabel => _t(
      'Sermon points', 'ప్రసంగ ముఖ్యాంశాలు', 'प्रवचन के मुख्य बिंदु');
  String get refsLabel => _t(
      'Scripture references', 'లేఖన సూచనలు', 'पवित्रशास्त्र संदर्भ');
  String get notesLabel =>
      _t('Notes & reflections', 'నోట్స్ & ధ్యానం', 'नोट्स और मनन');
  String get add => _t('Add', 'చేర్చు', 'जोड़ें');
  String get notesHint => _t('Your reflections, prayers, takeaways…',
      'మీ ధ్యానం, ప్రార్థనలు, నేర్చుకున్నవి…', 'आपका मनन, प्रार्थनाएँ, सीख…');
  String get pointHint => _t('Add a sermon point…',
      'ప్రసంగ అంశాన్ని చేర్చండి…', 'प्रवचन का बिंदु जोड़ें…');
  String get addPointTip => _t('Add point', 'అంశం చేర్చు', 'बिंदु जोड़ें');
  String get addRefTip => _t('Add scripture reference', 'లేఖన సూచన చేర్చు',
      'संदर्भ जोड़ें');
  String get openInBible =>
      _t('Open in Bible', 'బైబిల్‌లో తెరవండి', 'बाइबल में खोलें');
  String get verseTextMissing => _t(
      'Verse text not stored for this reference.',
      'ఈ సూచనకు వచన పాఠం నిల్వ చేయలేదు.',
      'इस संदर्भ का वचन पाठ सहेजा नहीं गया।');

  // ------------------------------------------------------------ add reference
  String get addRefTitle => _t('Add scripture reference',
      'లేఖన సూచన చేర్చండి', 'पवित्रशास्त्र संदर्भ जोड़ें');
  String get chapterField => _t('Chapter', 'అధ్యాయం', 'अध्याय');
  String get verseField =>
      _t('Verse (optional)', 'వచనం (ఐచ్ఛికం)', 'वचन (वैकल्पिक)');
  String get verseFieldHint =>
      _t('16 or 16-18', '16 లేదా 16-18', '16 या 16-18');
  String errChapter(int max) => _t(
      'Chapter must be 1–$max',
      'అధ్యాయం 1–$max మధ్య ఉండాలి',
      'अध्याय 1–$max के बीच होना चाहिए');
  String get errVerseFormat => _t('Verse like 16 or 16-18',
      'వచనం 16 లేదా 16-18 లాగా ఉండాలి', 'वचन 16 या 16-18 जैसा हो');
  String errVerseMissing(int max) => _t(
      'This chapter has only $max verses',
      'ఈ అధ్యాయంలో $max వచనాలు మాత్రమే ఉన్నాయి',
      'इस अध्याय में केवल $max वचन हैं');
  String get addRefButton =>
      _t('Add reference', 'సూచనను చేర్చు', 'संदर्भ जोड़ें');
  String get adding => _t('Adding…', 'చేర్చుతోంది…', 'जोड़ रहा है…');

  // ------------------------------------------------------------ saved list
  String get noSaved => _t('No saved sermons yet.',
      'ఇంకా సేవ్ చేసిన ప్రసంగాలు లేవు.', 'अभी कोई सहेजा गया प्रवचन नहीं।');
  String get untitled =>
      _t('Untitled sermon', 'శీర్షిక లేని ప్రసంగం', 'बिना शीर्षक का प्रवचन');
  String get deleteQuestion => _t('Delete this sermon note?',
      'ఈ ప్రసంగ నోట్‌ను తొలగించాలా?', 'यह प्रवचन नोट हटाएँ?');
  String get cannotUndo => _t('This cannot be undone.',
      'దీనిని తిరిగి పొందలేరు.', 'इसे वापस नहीं किया जा सकता।');
  String get cancel => _t('Cancel', 'రద్దు', 'रद्द करें');
  String get delete => _t('Delete', 'తొలగించు', 'हटाएँ');

  // ------------------------------------------------------------ capture bar
  String get addPointLabel => _t('Point', 'అంశం', 'बिंदु');
  String get addVerseLabel => _t('Verse', 'వాక్యం', 'वचन');
  String get saveNote => _t('Save', 'సేవ్', 'सहेजें');
  String get savedNow =>
      _t('Saved', 'సేవ్ అయింది', 'सहेज लिया');
  String get addPointTipFull => _t('Add this as a sermon point',
      'దీనిని ప్రసంగ అంశంగా చేర్చండి', 'इसे प्रवचन बिंदु के रूप में जोड़ें');
  String get addVerseTipFull => _t('Add a scripture reference',
      'లేఖన సూచనను చేర్చండి', 'पवित्रशास्त्र संदर्भ जोड़ें');
  String get saveNoteTip => _t('Save this sermon note',
      'ఈ ప్రసంగ నోట్‌ను సేవ్ చేయండి', 'यह प्रवचन नोट सहेजें');

  // ------------------------------------------------------------ validation
  String rangeHint(int max) => '(1 \u2013 $max)';
  String errVerseRange(int max) => _t(
      'Verse must be 1\u2013$max',
      'వచనం 1\u2013$max మధ్య ఉండాలి',
      'वचन 1\u2013$max के बीच होना चाहिए');

  // ------------------------------------------------------------ study toolkit
  String get settingsTitle => _t('Study & Settings',
      'అధ్యయనం & సెట్టింగ్‌లు', 'अध्ययन और सेटिंग्स');
  String get bookmarks => _t('Bookmarks', 'బుక్‌మార్క్‌లు', 'बुकमार्क');
  String get favorites => _t('Favorites', 'ఇష్టమైనవి', 'पसंदीदा');
  String get readingHistory =>
      _t('Reading History', 'పఠన చరిత్ర', 'पठन इतिहास');
  String get readingTheme => _t('Reading Theme', 'పఠన థీమ్', 'पठन थीम');
  String get rateApp =>
      _t('Rate App', 'యాప్‌కు రేటింగ్ ఇవ్వండి', 'ऐप को रेट करें');
  String get shareApp =>
      _t('Share App', 'యాప్‌ను షేర్ చేయండి', 'ऐप शेयर करें');
  String get aboutUs => _t('About Us', 'మా గురించి', 'हमारे बारे में');
  String get shareVerse =>
      _t('Share verse', 'వచనాన్ని షేర్ చేయండి', 'वचन शेयर करें');
  String get copied => _t('Copied to clipboard',
      'క్లిప్‌బోర్డ్‌కు కాపీ చేయబడింది', 'क्लिपबोर्ड पर कॉपी किया गया');
  String get storeOpenFailed => _t('Could not open the store',
      'స్టోర్‌ను తెరవలేకపోయాము', 'स्टोर नहीं खुल सका');
  String shareAppMessage(String url) => _t(
      'Read the Bible in Telugu, English and Hindi, and keep your sermon notes in one place \u2014 Scripture & Sermon Studio\n$url',
      'తెలుగు, ఇంగ్లీష్, హిందీలో బైబిల్ చదవండి, మీ ప్రసంగ నోట్స్ ఒకే చోట ఉంచండి \u2014 Scripture & Sermon Studio\n$url',
      'तेलुगु, अंग्रेज़ी और हिंदी में बाइबल पढ़ें और अपने प्रवचन नोट्स एक ही जगह रखें \u2014 Scripture & Sermon Studio\n$url');
  String get loadFailed => _t('This chapter could not be loaded.',
      'ఈ అధ్యాయాన్ని లోడ్ చేయలేకపోయాము.', 'यह अध्याय लोड नहीं हो सका।');
  String get retry => _t('Try again', 'మళ్లీ ప్రయత్నించండి', 'फिर कोशिश करें');
  String get noBookmarks => _t(
      'No bookmarks yet. Tap the bookmark icon on any verse to keep it here.',
      'ఇంకా బుక్‌మార్క్‌లు లేవు. ఏదైనా వచనంలోని బుక్‌మార్క్ చిహ్నాన్ని నొక్కండి.',
      'अभी कोई बुकमार्क नहीं। किसी भी वचन पर बुकमार्क आइकन दबाएँ।');
  String get noFavorites => _t(
      'No favorites yet. Tap the star on any verse to keep it here.',
      'ఇంకా ఇష్టమైనవి లేవు. ఏదైనా వచనంలోని నక్షత్రాన్ని నొక్కండి.',
      'अभी कोई पसंदीदा नहीं। किसी भी वचन पर तारा दबाएँ।');
  String get noHistory => _t(
      'Chapters you read will appear here.',
      'మీరు చదివిన అధ్యాయాలు ఇక్కడ కనిపిస్తాయి.',
      'आपके पढ़े हुए अध्याय यहाँ दिखाई देंगे।');
  String get remove => _t('Remove', 'తొలగించు', 'हटाएँ');
  String get clearHistory =>
      _t('Clear history', 'చరిత్రను తొలగించు', 'इतिहास साफ़ करें');
  String get clearHistoryQuestion => _t('Clear your reading history?',
      'మీ పఠన చరిత్రను తొలగించాలా?', 'पठन इतिहास साफ़ करें?');
  String get today => _t('Today', 'ఈ రోజు', 'आज');
  String get yesterday => _t('Yesterday', 'నిన్న', 'कल');
  String get wholeChapter =>
      _t('Whole chapter', 'మొత్తం అధ్యాయం', 'पूरा अध्याय');
  String get themeSheetTitle =>
      _t('Reading theme', 'పఠన థీమ్', 'पठन थीम');
  String get themeSheetNote => _t(
      'Soft, glare-free colours for long reading. Your choice is remembered.',
      'ఎక్కువసేపు చదవడానికి మృదువైన, కాంతి లేని రంగులు. మీ ఎంపిక గుర్తుంచబడుతుంది.',
      'लंबे पठन के लिए कोमल, चकाचौंध-रहित रंग। आपकी पसंद याद रखी जाती है।');

  String themeName(String id) {
    switch (id) {
      case 'sage':
        return _t('Soft Sage', 'మృదువైన సేజ్', 'कोमल सेज');
      case 'cream':
        return _t('Paper Cream', 'పేపర్ క్రీమ్', 'पेपर क्रीम');
      case 'midnight':
        return _t('Midnight Charcoal', 'అర్ధరాత్రి చార్‌కోల్', 'मध्यरात्रि चारकोल');
      default:
        return _t('Warm Parchment', 'వెచ్చని పార్చ్‌మెంట్', 'गर्म चर्मपत्र');
    }
  }

  String themeNote(String id) {
    switch (id) {
      case 'sage':
        return _t('Calm green-grey, gentle in daylight',
            'ప్రశాంతమైన ఆకుపచ్చ-బూడిద రంగు, పగటికి మృదువు',
            'शांत हरा-धूसर, दिन में कोमल');
      case 'cream':
        return _t('Light neutral paper for bright rooms',
            'ప్రకాశవంతమైన గదులకు తేలికపాటి కాగితం',
            'उजले कमरों के लिए हल्का कागज़');
      case 'midnight':
        return _t('Dark and warm, for night prayer',
            'రాత్రి ప్రార్థనకు చీకటి, వెచ్చని రంగు',
            'रात की प्रार्थना के लिए गहरा और गर्म');
      default:
        return _t('Classic study-Bible paper',
            'సాంప్రదాయ అధ్యయన బైబిల్ కాగితం',
            'क्लासिक अध्ययन-बाइबल पन्ना');
    }
  }

  // ------------------------------------------------------------ dates
  static const List<String> _enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _teMonths = [
    'జనవరి', 'ఫిబ్రవరి', 'మార్చి', 'ఏప్రిల్', 'మే', 'జూన్',
    'జూలై', 'ఆగస్టు', 'సెప్టెంబర్', 'అక్టోబర్', 'నవంబర్', 'డిసెంబర్',
  ];
  static const List<String> _hiMonths = [
    'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुलाई', 'अगस्त', 'सितंबर', 'अक्तूबर', 'नवंबर', 'दिसंबर',
  ];

  String monthName(int month) {
    final List<String> m =
        lang == 'te' ? _teMonths : (lang == 'hi' ? _hiMonths : _enMonths);
    return m[(month - 1).clamp(0, 11)];
  }

  String formatDate(DateTime d) => lang == 'en'
      ? '${monthName(d.month)} ${d.day}, ${d.year}'
      : '${d.day} ${monthName(d.month)} ${d.year}';

  String formatMonth(DateTime d) => '${monthName(d.month)} ${d.year}';

  /// "14:05" style time of day for the reading history.
  String formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
