import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/screens/verify_otp_screen.dart';

/// Demo app to showcase the OTP Verification Screen
/// Run this file to see the pixel-perfect OTP implementation
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

  runApp(const VerifyOTPDemoApp());
}

class VerifyOTPDemoApp extends StatelessWidget {
  const VerifyOTPDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verify OTP Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        fontFamily: 'SF Pro Display', // iOS-like font
        useMaterial3: true,
      ),
      home: const VerifyOTPScreen(
        mobileNumber: '+1 234 567 8900',
      ),
    );
  }
}
