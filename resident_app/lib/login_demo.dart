import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/login_screen.dart';

/// Demo app to showcase the Login Screen
/// Run this file to see the pixel-perfect login implementation
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI to light mode for status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  
  runApp(const LoginDemoApp());
}

class LoginDemoApp extends StatelessWidget {
  const LoginDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display', // iOS-like font
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
