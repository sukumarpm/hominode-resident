import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/screens/onboarding_flow.dart';

/// Standalone runnable demo for onboarding flow
/// Run with: flutter run -t lib/onboarding_main.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const OnboardingApp());
}

class OnboardingApp extends MaterialApp {
  const OnboardingApp({super.key})
    : super(
        title: 'Onboarding Flow',
        debugShowCheckedModeBanner: false,
        home: const OnboardingFlow(),
        routes: const {'/home': _buildHomePlaceholder},
      );

  static Widget _buildHomePlaceholder(BuildContext context) {
    return const HomePlaceholder();
  }
}

/// Placeholder home screen for demo purposes
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Color(0xFF0E4778),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to the App!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Onboarding completed successfully',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                // Clear onboarding flag for testing
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('onboarding_completed');

                if (!context.mounted) return;

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingFlow(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E4778),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Restart Onboarding',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
