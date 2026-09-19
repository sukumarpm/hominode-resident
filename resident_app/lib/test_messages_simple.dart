// Simple Messages Test
// Run this to see console logs

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/screens/messages_screen_enhanced.dart';
import 'src/services/firestore_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Login first
  final authService = FirestoreAuthService.instance;
  print('\n========================================');
  print('🔐 LOGGING IN');
  print('========================================\n');
  
  final result = await authService.signInFirestoreOnly(
    identifier: 'preethampriyatharson07@gmail.com',
    password: 'tK7Fo1Ow',
  );
  
  if (result.success) {
    print('\n✅ Login successful!');
    print('User ID: ${result.userId}');
    print('Name: ${result.userData?['name']}');
  } else {
    print('\n❌ Login failed: ${result.message}');
  }
  
  print('\n========================================');
  print('📱 LAUNCHING MESSAGES SCREEN');
  print('========================================\n');
  
  runApp(const TestMessagesApp());
}

class TestMessagesApp extends StatelessWidget {
  const TestMessagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Messages',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MessagesScreenEnhanced(),
    );
  }
}
