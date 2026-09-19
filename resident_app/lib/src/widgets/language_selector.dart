import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  final bool showTitle;
  final bool isCompact;

  const LanguageSelector({
    super.key,
    this.showTitle = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        if (isCompact) {
          return _buildCompactSelector(context, languageProvider);
        }

        return _buildFullSelector(context, languageProvider);
      },
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LanguageProvider.supportedLanguages.map((langCode) {
          final isSelected = languageProvider.currentLanguageCode == langCode;
          final langName = LanguageProvider.languageNames[langCode] ?? langCode;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FilterChip(
              selected: isSelected,
              label: Text(langName),
              onSelected: (selected) {
                if (selected) {
                  languageProvider.setLanguage(langCode);
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF0E4778),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFullSelector(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'settings_select_language'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (languageProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: LanguageProvider.supportedLanguages.length,
            itemBuilder: (context, index) {
              final langCode = LanguageProvider.supportedLanguages[index];
              final isSelected =
                  languageProvider.currentLanguageCode == langCode;
              final langName =
                  LanguageProvider.languageNames[langCode] ?? langCode;

              return _buildLanguageCard(
                context,
                langCode,
                langName,
                isSelected,
                () {
                  languageProvider.setLanguage(langCode);
                },
              );
            },
          ),
        if (languageProvider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              languageProvider.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    String langCode,
    String langName,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E4778) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0E4778)
                : const Color(0xFFE6E6E6),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0E4778).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              langCode.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF9B9B9B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              langName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF111111),
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
