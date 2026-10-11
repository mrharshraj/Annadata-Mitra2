import 'package:flutter/widgets.dart';

/// Minimal Flutter-localization implementation (no codegen) covering all
/// 20 Stitch screens in English + Hindi. Screens 11–20 had no Hindi
/// prototype, so Hindi strings here are fresh translations that keep the
/// same layout and meaning.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(l != null, 'AppLocalizations not found in widget tree');
    return l!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  String get _code => locale.languageCode == 'hi' ? 'hi' : 'en';

  String _t(String key) => _values[key]?[_code] ?? _values[key]?['en'] ?? key;

  // Brand / chrome
  String get appName => _t('appName');
  String get navHome => _t('navHome');
  String get navCrops => _t('navCrops');
  String get navAi => _t('navAi');
  String get navTasks => _t('navTasks');
  String get navProfile => _t('navProfile');

  // 01 Splash
  String get splashTitle => _t('splashTitle');
  String get splashSubtitle => _t('splashSubtitle');
  String get splashLoading => _t('splashLoading');

  // 02 Welcome
  String get welcomeTitle => _t('welcomeTitle');
  String get welcomeSubtitle => _t('welcomeSubtitle');
  String get welcomeCta => _t('welcomeCta');

  // 03 Sign in
  String get signInTitle => _t('signInTitle');
  String get signInSubtitle => _t('signInSubtitle');
  String get signInCta => _t('signInCta');

  // 04 Location
  String get locationTitle => _t('locationTitle');
  String get locationSubtitle => _t('locationSubtitle');
  String get locationDetect => _t('locationDetect');
  String get locationNext => _t('locationNext');

  // 05 Farm profile
  String get farmTitle => _t('farmTitle');
  String get farmSubtitle => _t('farmSubtitle');
  String get farmSizeLabel => _t('farmSizeLabel');
  String get farmNext => _t('farmNext');

  // 06 Add crop
  String get addCropTitle => _t('addCropTitle');
  String get addCropSubtitle => _t('addCropSubtitle');
  String get addCropCta => _t('addCropCta');

  // 07 Dashboard
  String get dashboardGreeting => _t('dashboardGreeting');
  String get dashboardHeroTitle => _t('dashboardHeroTitle');
  String get dashboardHeroBody => _t('dashboardHeroBody');
  String get dashboardWeather => _t('dashboardWeather');
  String get dashboardCrops => _t('dashboardCrops');

  // 08 Weather
  String get weatherTitle => _t('weatherTitle');
  String get weatherSubtitle => _t('weatherSubtitle');
  String get weatherDetails => _t('weatherDetails');

  // 09 Forecast
  String get forecastTitle => _t('forecastTitle');
  String get forecastSubtitle => _t('forecastSubtitle');

  // 10 Advisory
  String get advisoryTitle => _t('advisoryTitle');
  String get advisorySubtitle => _t('advisorySubtitle');

  // 11 Crops
  String get cropsTitle => _t('cropsTitle');
  String get cropsSubtitle => _t('cropsSubtitle');
  String get cropsAdd => _t('cropsAdd');

  // 12 Crop details
  String get cropDetailsTitle => _t('cropDetailsTitle');
  String get cropDetailsStage => _t('cropDetailsStage');

  // 13 Scanner
  String get scannerTitle => _t('scannerTitle');
  String get scannerSubtitle => _t('scannerSubtitle');
  String get scannerCta => _t('scannerCta');

  // 14 Ask AI
  String get askAiTitle => _t('askAiTitle');
  String get askAiSubtitle => _t('askAiSubtitle');
  String get askAiSpeak => _t('askAiSpeak');

  // 15 Conversation
  String get conversationTitle => _t('conversationTitle');
  String get conversationHint => _t('conversationHint');
  String get conversationSend => _t('conversationSend');

  // 16 Tasks
  String get tasksTitle => _t('tasksTitle');
  String get tasksSubtitle => _t('tasksSubtitle');
  String get tasksAdd => _t('tasksAdd');

  // 17 Task details
  String get taskDetailsTitle => _t('taskDetailsTitle');

  // 18 Timeline
  String get timelineTitle => _t('timelineTitle');
  String get timelineSubtitle => _t('timelineSubtitle');

  // 19 Fields
  String get fieldsTitle => _t('fieldsTitle');
  String get fieldsSubtitle => _t('fieldsSubtitle');
  String get fieldsAdd => _t('fieldsAdd');

  // 20 Profile
  String get profileTitle => _t('profileTitle');
  String get profileLanguage => _t('profileLanguage');
  String get profileLogout => _t('profileLogout');

  // Shared actions
  String get actionBack => _t('actionBack');
  String get actionSave => _t('actionSave');
  String get actionRetry => _t('actionRetry');
  String get phase1Note => _t('phase1Note');
  String get privacyTitle => _t('privacyTitle');
  String get privacyDelete => _t('privacyDelete');
  String get privacyDeleteTitle => _t('privacyDeleteTitle');
  String get privacyDeleteBody => _t('privacyDeleteBody');

  static const Map<String, Map<String, String>> _values = {
    'appName': {'en': 'ANNADATA MITRA', 'hi': 'अन्नदाता मित्र'},
    'navHome': {'en': 'HOME', 'hi': 'होम'},
    'navCrops': {'en': 'CROPS', 'hi': 'फसलें'},
    'navAi': {'en': 'AI', 'hi': 'एआई'},
    'navTasks': {'en': 'TASKS', 'hi': 'काम'},
    'navProfile': {'en': 'PROFILE', 'hi': 'प्रोफ़ाइल'},
    'splashTitle': {'en': 'Annadata Mitra', 'hi': 'अन्नदाता मित्र'},
    'splashSubtitle': {
      'en': 'AI FARMING INTELLIGENCE SYSTEM',
      'hi': 'एआई खेती इंटेलिजेंस प्रणाली',
    },
    'splashLoading': {
      'en': 'Initializing Neural Links...',
      'hi': 'न्यूरल लिंक प्रारंभ हो रहा है...',
    },
    'welcomeTitle': {
      'en': 'Smarter Farm Decisions Every Day',
      'hi': 'हर दिन समझदार खेती निर्णय',
    },
    'welcomeSubtitle': {
      'en': 'Soil, weather and AI daily plans for your village.',
      'hi': 'आपके गाँव के लिए मिट्टी, मौसम और एआई दैनिक योजना।',
    },
    'welcomeCta': {
      'en': 'GET STARTED',
      'hi': 'शुरू करें',
    },
    'signInTitle': {'en': 'Secure Farmer Sign In', 'hi': 'सुरक्षित किसान साइन इन'},
    'signInSubtitle': {
      'en': 'Use your Google account to sync crop data.',
      'hi': 'फसल डेटा समन्वय के लिए अपना Google खाता उपयोग करें।',
    },
    'signInCta': {'en': 'AUTHORIZE & CONTINUE', 'hi': 'अधिकृत करें और आगे बढ़ें'},
    'locationTitle': {'en': 'Where is your farm located?', 'hi': 'आपका खेत कहाँ है?'},
    'locationSubtitle': {
      'en': 'Step 1 of 3 — micro-climate forecasts for your plot.',
      'hi': 'चरण 1/3 — आपके खेत के लिए सूक्ष्म जलवायु पूर्वानुमान।',
    },
    'locationDetect': {'en': 'AUTO-DETECT LOCATION', 'hi': 'स्थान स्वतः पहचानें'},
    'locationNext': {'en': 'SAVE & CONTINUE', 'hi': 'सहेजें और आगे बढ़ें'},
    'farmTitle': {'en': 'Farm Profile', 'hi': 'खेत प्रोफ़ाइल'},
    'farmSubtitle': {
      'en': 'Step 2 of 3 — size and type tailor AI advice.',
      'hi': 'चरण 2/3 — आकार और प्रकार से एआई सलाह बनेगी।',
    },
    'farmSizeLabel': {'en': 'TOTAL FARM LAND (ACRES)', 'hi': 'कुल खेत भूमि (एकड़)'},
    'farmNext': {'en': 'SAVE & CONTINUE', 'hi': 'सहेजें और आगे बढ़ें'},
    'addCropTitle': {'en': 'Add your active crop', 'hi': 'अपनी सक्रिय फसल जोड़ें'},
    'addCropSubtitle': {
      'en': 'Step 3 of 3 — enable growth and water tracking.',
      'hi': 'चरण 3/3 — वृद्धि और पानी ट्रैकिंग चालू करें।',
    },
    'addCropCta': {'en': 'COMPLETE SETUP', 'hi': 'सेटअप पूर्ण करें'},
    'dashboardGreeting': {'en': 'GOOD MORNING, RAMESH', 'hi': 'सुप्रभात, रमेश'},
    'dashboardHeroTitle': {
      'en': 'RAIN EXPECTED TOMORROW. POSTPONE WHEAT IRRIGATION.',
      'hi': 'कल बारिश संभव। गेहूँ सिंचाई टालें।',
    },
    'dashboardHeroBody': {
      'en': 'Prototype layout — live advisory arrives in Phase 8.',
      'hi': 'प्रोटोटाइप लेआउट — लाइव सलाह चरण 8 में आएगी।',
    },
    'dashboardWeather': {'en': "TODAY'S WEATHER", 'hi': 'आज का मौसम'},
    'dashboardCrops': {'en': 'CROP STATUS', 'hi': 'फसल स्थिति'},
    'weatherTitle': {'en': 'Weather Overview', 'hi': 'मौसम अवलोकन'},
    'weatherSubtitle': {'en': 'Nilokheri, Karnal — prototype data.', 'hi': 'निलोखेड़ी, करनाल — प्रोटोटाइप डेटा।'},
    'weatherDetails': {'en': 'VIEW DETAILED FORECAST', 'hi': 'विस्तृत पूर्वानुमान देखें'},
    'forecastTitle': {'en': 'Detailed Forecast', 'hi': 'विस्तृत पूर्वानुमान'},
    'forecastSubtitle': {
      'en': 'Hourly runoff and precipitation, prototype only.',
      'hi': 'घंटेवार अपवाह और वर्षा, केवल प्रोटोटाइप।',
    },
    'advisoryTitle': {'en': 'AI Recommendations', 'hi': 'एआई सिफारिशें'},
    'advisorySubtitle': {
      'en': 'Irrigation, pest and nutrition queue.',
      'hi': 'सिंचाई, कीट और पोषण सूची।',
    },
    'cropsTitle': {'en': 'My Crops', 'hi': 'मेरी फसलें'},
    'cropsSubtitle': {
      'en': '3 active crops across 8.5 acres (layout sample).',
      'hi': '8.5 एकड़ में 3 सक्रिय फसलें (लेआउट नमूना)।',
    },
    'cropsAdd': {'en': 'ADD NEW CROP', 'hi': 'नई फसल जोड़ें'},
    'cropDetailsTitle': {'en': 'WHEAT — PBW-550', 'hi': 'गेहूँ — पीबीडब्ल्यू-550'},
    'cropDetailsStage': {
      'en': 'Stage: Tillering, Day 42 (sample).',
      'hi': 'अवस्था: कल्ले निकलना, दिन 42 (नमूना)।',
    },
    'scannerTitle': {'en': 'Crop Health Scanner', 'hi': 'फसल स्वास्थ्य स्कैनर'},
    'scannerSubtitle': {
      'en': 'Camera analysis lands in Phase 10.',
      'hi': 'कैमरा विश्लेषण चरण 10 में आएगा।',
    },
    'scannerCta': {'en': 'OPEN CAMERA (PHASE 10)', 'hi': 'कैमरा खोलें (चरण 10)'},
    'askAiTitle': {'en': 'AI MITRA', 'hi': 'एआई मित्र'},
    'askAiSubtitle': {
      'en': 'Voice-first help, synced with field context.',
      'hi': 'खेत संदर्भ के साथ वॉयस-पहली सहायता।',
    },
    'askAiSpeak': {'en': 'TAP TO SPEAK', 'hi': 'बोलने के लिए टैप करें'},
    'conversationTitle': {'en': 'AI Conversation', 'hi': 'एआई वार्तालाप'},
    'conversationHint': {
      'en': 'Ask about wheat, mustard, weather...',
      'hi': 'गेहूँ, सरसों, मौसम के बारे में पूछें...',
    },
    'conversationSend': {'en': 'SEND', 'hi': 'भेजें'},
    'tasksTitle': {'en': 'Farm Tasks', 'hi': 'खेत कार्य'},
    'tasksSubtitle': {
      'en': 'Weather-prioritized to-do list (sample).',
      'hi': 'मौसम-प्राथमिकता कार्य सूची (नमूना)।',
    },
    'tasksAdd': {'en': 'CREATE TASK', 'hi': 'कार्य बनाएँ'},
    'taskDetailsTitle': {'en': 'Task Details', 'hi': 'कार्य विवरण'},
    'timelineTitle': {'en': 'Activity Timeline', 'hi': 'गतिविधि समयरेखा'},
    'timelineSubtitle': {
      'en': 'Rabi 2024-25 log (layout sample).',
      'hi': 'रबी 2024-25 लॉग (लेआउट नमूना)।',
    },
    'fieldsTitle': {'en': 'Farm Land & Fields', 'hi': 'खेत भूमि और खेत'},
    'fieldsSubtitle': {
      'en': '8.5 acres across 3 parcels (sample).',
      'hi': '3 भूखंडों में 8.5 एकड़ (नमूना)।',
    },
    'fieldsAdd': {'en': 'ADD FIELD', 'hi': 'खेत जोड़ें'},
    'profileTitle': {'en': 'Profile & System Hub', 'hi': 'प्रोफ़ाइल और सिस्टम हब'},
    'profileLanguage': {'en': 'LANGUAGE / भाषा', 'hi': 'भाषा / LANGUAGE'},
    'profileLogout': {'en': 'SIGN OUT', 'hi': 'साइन आउट'},
    'actionBack': {'en': 'BACK', 'hi': 'पीछे'},
    'actionSave': {'en': 'SAVE', 'hi': 'सहेजें'},
    'actionRetry': {'en': 'RETRY', 'hi': 'पुनः प्रयास'},
    'phase1Note': {
      'en': 'Phase 1 UI shell — real data connects in later phases.',
      'hi': 'चरण 1 यूआई खोल — वास्तविक डेटा बाद के चरणों में जुड़ेगा।',
    },
    'privacyTitle': {'en': 'Privacy Policy', 'hi': 'गोपनीयता नीति'},
    'privacyDelete': {'en': 'DELETE MY DATA', 'hi': 'मेरा डेटा हटाएं'},
    'privacyDeleteTitle': {
      'en': 'Delete all my farm data?',
      'hi': 'मेरा सारा खेत डेटा हटाएं?',
    },
    'privacyDeleteBody': {
      'en':
          'Your profile, fields, crops, tasks, scans and AI history will be permanently deleted, then you will be signed out.',
      'hi':
          'आपकी प्रोफ़ाइल, खेत, फसलें, कार्य, स्कैन और एआई इतिहास स्थायी रूप से हटा दिया जाएगा, फिर आपको साइन आउट किया जाएगा।',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
