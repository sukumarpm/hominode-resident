// Test file to verify admin chat and flat members functionality
// Run: flutter run -d <device_id> -t lib/test_messages_admin_chat.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/screens/messages_screen_enhanced.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const TestMessagesApp());
}

class TestMessagesApp extends StatelessWidget {
  const TestMessagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Messages - Admin Chat & Flat Members',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MessagesScreenEnhanced(),
    );
  }
}
