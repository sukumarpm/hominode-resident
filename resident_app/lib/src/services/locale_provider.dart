// lib/src/services/locale_provider.dart
// Locale management service for app language

import 'package:flutter/material.dart';

/// Service to manage app locale/language preferences
/// This is a stub implementation - integrate with your state management
class LocaleProvider extends ChangeNotifier {
  // Singleton pattern
  static final LocaleProvider _instance = LocaleProvider._internal();
  factory LocaleProvider() => _instance;
  LocaleProvider._internal();

  // In-memory storage (replace with SharedPreferences or state management)
  Locale _currentLocale = const Locale('en');

  /// Get current locale
  Future<Locale> getLocale() async {
    // TODO: Load from SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // final languageCode = prefs.getString('language_code') ?? 'en';
    // _currentLocale = Locale(languageCode);
    
    return _currentLocale;
  }

  /// Set new locale
  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    
    // TODO: Save to SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('language_code', locale.languageCode);
    
    // Notify listeners (if using ChangeNotifier pattern)
    notifyListeners();
    
    // TODO: Sync to backend
    // await _syncToBackend(locale.languageCode);
    
    print('Locale changed to: ${locale.languageCode}');
  }

  /// Get current locale synchronously
  Locale get currentLocale => _currentLocale;

  /// Check if current locale is RTL
  bool get isRTL {
    return _currentLocale.languageCode == 'ar' ||
        _currentLocale.languageCode == 'he' ||
        _currentLocale.languageCode == 'fa' ||
        _currentLocale.languageCode == 'ur';
  }

  /// Get text direction based on current locale
  TextDirection get textDirection {
    final directionString = isRTL ? 'rtl' : 'ltr';
    return directionString == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Sync locale to backend (stub)
  Future<void> _syncToBackend(String languageCode) async {
    // TODO: Implement backend sync
    // Example:
    // await http.put(
    //   Uri.parse('$baseUrl/api/user/preferences'),
    //   body: jsonEncode({'language': languageCode}),
    // );
  }
}

/// Supported locales for the app
class AppLocales {
  static const Locale english = Locale('en');
  static const Locale hindi = Locale('hi');
  static const Locale tamil = Locale('ta');
  static const Locale spanish = Locale('es');
  static const Locale arabic = Locale('ar');

  static const List<Locale> supported = [
    english,
    hindi,
    tamil,
    spanish,
    arabic,
  ];

  /// Get locale name
  static String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'Hindi';
      case 'ta':
        return 'Tamil';
      case 'es':
        return 'Spanish';
      case 'ar':
        return 'Arabic';
      default:
        return 'Unknown';
    }
  }

  /// Get native locale name
  static String getNativeLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'ta':
        return 'தமிழ்';
      case 'es':
        return 'Español';
      case 'ar':
        return 'العربية';
      default:
        return 'Unknown';
    }
  }

  /// Check if locale is RTL
  static bool isRTL(Locale locale) {
    return locale.languageCode == 'ar' ||
        locale.languageCode == 'he' ||
        locale.languageCode == 'fa' ||
        locale.languageCode == 'ur';
  }
}
