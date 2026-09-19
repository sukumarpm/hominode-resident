// lib/src/widgets/language_switcher.dart
// Language Switcher Widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';

// ============================================================================
// LANGUAGE SWITCHER WIDGET
// ============================================================================
class LanguageSwitcher extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onLanguageChanged;

  const LanguageSwitcher({
    super.key,
    this.isCompact = false,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, _) {
        if (isCompact) {
          return _buildCompactSwitcher(context, localizationProvider);
        }
        return _buildFullSwitcher(context, localizationProvider);
      },
    );
  }

  // ========================================================================
  // COMPACT SWITCHER (Dropdown)
  // ========================================================================
  Widget _buildCompactSwitcher(
    BuildContext context,
    LocalizationProvider provider,
  ) {
    return DropdownButton<String>(
      value: provider.currentLanguage,
      items: provider.supportedLanguages.map((language) {
        return DropdownMenuItem<String>(
          value: language,
          child: Row(
            children: [
              _getLanguageFlag(language),
              const SizedBox(width: 8),
              Text(provider.getLanguageName(language)),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? newLanguage) async {
        if (newLanguage != null) {
          await provider.setLanguage(newLanguage);
          onLanguageChanged?.call();
        }
      },
      underline: Container(),
      icon: const Icon(Icons.language, color: Color(0xFF0E4778)),
    );
  }

  // ========================================================================
  // FULL SWITCHER (Grid)
  // ========================================================================
  Widget _buildFullSwitcher(
    BuildContext context,
    LocalizationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Language',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: provider.supportedLanguages.length,
          itemBuilder: (context, index) {
            final language = provider.supportedLanguages[index];
            final isSelected = provider.currentLanguage == language;

            return GestureDetector(
              onTap: () async {
                await provider.setLanguage(language);
                onLanguageChanged?.call();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0E4778)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0E4778)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getLanguageFlagLarge(language),
                    const SizedBox(height: 8),
                    Text(
                      provider.getLanguageName(language),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================
  Widget _getLanguageFlag(String languageCode) {
    const flagMap = {
      'en': '🇬🇧',
      'ta': '🇮🇳',
      'hi': '🇮🇳',
      'es': '🇪🇸',
      'ar': '🇸🇦',
    };
    return Text(
      flagMap[languageCode] ?? '🌐',
      style: const TextStyle(fontSize: 20),
    );
  }

  Widget _getLanguageFlagLarge(String languageCode) {
    const flagMap = {
      'en': '🇬🇧',
      'ta': '🇮🇳',
      'hi': '🇮🇳',
      'es': '🇪🇸',
      'ar': '🇸🇦',
    };
    return Text(
      flagMap[languageCode] ?? '🌐',
      style: const TextStyle(fontSize: 32),
    );
  }
}

// ============================================================================
// LANGUAGE SWITCHER DIALOG
// ============================================================================
class LanguageSwitcherDialog extends StatelessWidget {
  final VoidCallback? onLanguageChanged;

  const LanguageSwitcherDialog({super.key, this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, _) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: localizationProvider.supportedLanguages.map((language) {
                final isSelected =
                    localizationProvider.currentLanguage == language;

                return ListTile(
                  leading: Text(
                    _getLanguageFlag(language),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(localizationProvider.getLanguageName(language)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF0E4778))
                      : null,
                  onTap: () async {
                    await localizationProvider.setLanguage(language);
                    onLanguageChanged?.call();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _getLanguageFlag(String languageCode) {
    const flagMap = {
      'en': '🇬🇧',
      'ta': '🇮🇳',
      'hi': '🇮🇳',
      'es': '🇪🇸',
      'ar': '🇸🇦',
    };
    return flagMap[languageCode] ?? '🌐';
  }
}
