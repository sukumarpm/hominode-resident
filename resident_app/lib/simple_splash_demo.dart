import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/simple_splash_screen.dart';
import 'src/screens/login_screen.dart';

/// Demo app to test the pixel-perfect splash screen
/// Run: flutter run -t lib/simple_splash_demo.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI to light mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const SimpleSplashDemoApp());
}

class SimpleSplashDemoApp extends StatelessWidget {
  const SimpleSplashDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hominode - Splash Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2563EB),
      ),
      home: SimpleSplashScreen(
        onComplete: () {
          // Navigate to login after splash
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      ),
    );
  }
}
