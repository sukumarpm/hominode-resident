import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  
  factory LocalizationService() {
    return _instance;
  }
  
  LocalizationService._internal();

  Map<String, dynamic> _translations = {};
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  static const List<String> supportedLanguages = ['en', 'ta', 'hi', 'es', 'ar'];
  
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ta': 'Tamil',
    'hi': 'Hindi',
    'es': 'Spanish',
    'ar': 'Arabic',
  };

  Future<void> initialize(String languageCode) async {
    _currentLanguage = languageCode;
    await _loadTranslations(languageCode);
  }

  Future<void> _loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/l10n/translations_$languageCode.json',
      );
      _translations = jsonDecode(jsonString);
    } catch (e) {
      print('Error loading translations for $languageCode: $e');
      // Fallback to English
      if (languageCode != 'en') {
        await _loadTranslations('en');
      }
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) {
      print('Language $languageCode not supported');
      return;
    }
    _currentLanguage = languageCode;
    await _loadTranslations(languageCode);
  }

  String translate(String key, {Map<String, String>? params}) {
    String value = _translations[key]?.toString() ?? key;
    
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return value;
  }

  String t(String key, {Map<String, String>? params}) {
    return translate(key, params: params);
  }

  bool isRTL() {
    return _currentLanguage == 'ar';
  }

  TextDirection getTextDirection() {
    final directionString = isRTL() ? 'rtl' : 'ltr';
    return directionString == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
  }
}
