// lib/language_settings_demo.dart
// Demo file showing how to use the Language Settings Screen

import 'package:flutter/material.dart';
import 'src/screens/language_settings_screen.dart';
import 'src/services/locale_provider.dart';

void main() {
  runApp(const LanguageSettingsDemo());
}

class LanguageSettingsDemo extends StatefulWidget {
  const LanguageSettingsDemo({super.key});

  @override
  State<LanguageSettingsDemo> createState() => _LanguageSettingsDemoState();
}

class _LanguageSettingsDemoState extends State<LanguageSettingsDemo> {
  final LocaleProvider _localeProvider = LocaleProvider();
  Locale _currentLocale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _localeProvider.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Future<void> _loadLocale() async {
    final locale = await _localeProvider.getLocale();
    setState(() {
      _currentLocale = locale;
    });
  }

  void _onLocaleChanged() {
    setState(() {
      _currentLocale = _localeProvider.currentLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Settings Demo',
      debugShowCheckedModeBanner: false,
      locale: _currentLocale,
      supportedLocales: AppLocales.supported,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProvider();
    final currentLocale = localeProvider.currentLocale;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        title: const Text('Language Settings Demo'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.language,
                size: 80,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 24),
              const Text(
                'App Language',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Current: ${AppLocales.getLocaleName(currentLocale)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Change Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildFeatureList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Features:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('✓ 5 languages supported'),
          _buildFeatureItem('✓ Radio button selection'),
          _buildFeatureItem('✓ Current language indicator'),
          _buildFeatureItem('✓ RTL language support'),
          _buildFeatureItem('✓ Apply & Restart confirmation'),
          _buildFeatureItem('✓ Native language names'),
          _buildFeatureItem('✓ Flag emojis'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
