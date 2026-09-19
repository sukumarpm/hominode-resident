import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/animated_splash_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/create_account_screen.dart';
import 'src/screens/verify_otp_screen.dart';
import 'main_navigation.dart';
import 'src/providers/theme_provider.dart';

/// Complete Authentication Flow Demo
/// Demonstrates: Splash → Login → Create Account → OTP → Home
///
/// Run this to see the complete auth flow:
/// flutter run -t lib/auth_flow_demo.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI to light mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const AuthFlowDemoApp());
}

class AuthFlowDemoApp extends StatelessWidget {
  const AuthFlowDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hominode - Auth Flow Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => AnimatedSplashScreen(
          onAnimationComplete: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
          reduceMotion: false,
          simulateSlowDevice: false,
        ),
        '/login': (context) => const LoginScreen(),
        '/create-account': (context) => CreateAccountScreen(),
        '/verify-otp': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          return VerifyOTPScreen(mobileNumber: args?['mobile'] as String?);
        },
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}
