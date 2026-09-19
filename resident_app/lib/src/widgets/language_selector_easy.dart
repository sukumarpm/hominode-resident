import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/language_service.dart';

class LanguageSelectorEasy extends StatefulWidget {
  final VoidCallback? onLanguageChanged;

  const LanguageSelectorEasy({super.key, this.onLanguageChanged});

  @override
  State<LanguageSelectorEasy> createState() => _LanguageSelectorEasyState();
}

class _LanguageSelectorEasyState extends State<LanguageSelectorEasy> {
  late String _selectedLanguage;
  final _languageService = LanguageService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = context.locale.languageCode;
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() => _isLoading = true);

    try {
      // Change locale using EasyLocalization
      final localeMap = {
        'en': const Locale('en'),
        'ta': const Locale('ta'),
        'hi': const Locale('hi'),
        'es': const Locale('es'),
        'ar': const Locale('ar'),
      };

      final locale = localeMap[languageCode] ?? const Locale('en');
      await context.setLocale(locale);

      // Save to SharedPreferences and Firestore
      await _languageService.setLanguage(languageCode);

      setState(() => _selectedLanguage = languageCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('language_changed'.tr()),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      widget.onLanguageChanged?.call();
    } catch (e) {
      print('Error changing language: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_saving_language'.tr()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = LanguageService.getSupportedLanguages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'select_language'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final languageCode = languages.keys.toList()[index];
            final languageName = languages[languageCode]!;
            final isSelected = _selectedLanguage == languageCode;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0E4778)
                      : const Color(0xFFE6E6E6),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : () => _changeLanguage(languageCode),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Language flag/icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0E4778)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _getLanguageEmoji(languageCode),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Language name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF0E4778)
                                      : const Color(0xFF111111),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getLanguageNativeName(languageCode),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? const Color(0xFF0E4778)
                                      : const Color(0xFF9B9B9B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkmark
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF0E4778),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getLanguageEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'ta':
        return '🇮🇳';
      case 'hi':
        return '🇮🇳';
      case 'es':
        return '🇪🇸';
      case 'ar':
        return '🇸🇦';
      default:
        return '🌐';
    }
  }

  String _getLanguageNativeName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ta':
        return 'தமிழ்';
      case 'hi':
        return 'हिंदी';
      case 'es':
        return 'Español';
      case 'ar':
        return 'العربية';
      default:
        return '';
    }
  }
}
