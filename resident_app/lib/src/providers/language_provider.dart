import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/user_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageProvider extends ChangeNotifier {
  final UserDataService _userDataService = UserDataService();
  
  String _currentLanguageCode = 'en';
  bool _isLoading = false;
  String? _error;

  String get currentLanguageCode => _currentLanguageCode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get supportedLanguages => const ['en', 'ta', 'hi', 'es', 'ar'];

  static const List<String> _supportedLanguages = ['en', 'ta', 'hi', 'es', 'ar'];
  
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ta': 'Tamil',
    'hi': 'Hindi',
    'es': 'Spanish',
    'ar': 'العربية',
  };

  static const Map<String, String> languageCodes = {
    'en': 'EN',
    'ta': 'TA',
    'hi': 'HI',
    'es': 'ES',
    'ar': 'AR',
  };

  LanguageProvider() {
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to get user's saved language preference from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final savedLanguage = await _userDataService.getUserLanguagePreference(user.uid);
        if (savedLanguage != null && _supportedLanguages.contains(savedLanguage)) {
          _currentLanguageCode = savedLanguage;
        }
      }
    } catch (e) {
      _error = 'Error initializing language: $e';
      print(_error);
      _currentLanguageCode = 'en';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode, BuildContext context) async {
    if (!_supportedLanguages.contains(languageCode)) {
      _error = 'Language not supported';
      notifyListeners();
      return;
    }

    // If same language, skip
    if (_currentLanguageCode == languageCode) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Change language using EasyLocalization
      await context.setLocale(Locale(languageCode));
      _currentLanguageCode = languageCode;

      // Save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userDataService.saveUserLanguagePreference(user.uid, languageCode);
      }

      _error = null;
    } catch (e) {
      _error = 'Error changing language: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isRTL() {
    return _currentLanguageCode == 'ar';
  }

  /// Get text direction for Flutter widgets
  /// Returns 'rtl' for Arabic, 'ltr' for others
  String getTextDirectionString() {
    return isRTL() ? 'rtl' : 'ltr';
  }

  /// Get language display code (e.g., 'EN', 'TA', 'HI')
  String getLanguageCode(String languageCode) {
    return languageCodes[languageCode] ?? languageCode.toUpperCase();
  }

  /// Get language display name
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }

  /// Translate a key (for backward compatibility with existing code)
  /// This delegates to the LocalizationService
  String translate(String key, {Map<String, String>? params}) {
    // This is a placeholder - actual translation should use EasyLocalization's .tr()
    // in the UI. This method is here for backward compatibility only.
    return key;
  }
}
