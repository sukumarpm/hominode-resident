import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/create_account_screen.dart';

/// Demo app to showcase the Create Account Screen
/// Run this file to see the pixel-perfect implementation
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

  runApp(const CreateAccountDemoApp());
}

class CreateAccountDemoApp extends StatelessWidget {
  const CreateAccountDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Account Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        fontFamily: 'SF Pro Display', // iOS-like font
        useMaterial3: true,
      ),
      home: const CreateAccountScreen(),
    );
  }
}
