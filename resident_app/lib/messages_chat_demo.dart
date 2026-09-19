// lib/messages_chat_demo.dart
// Demo app to test the fixed Messages and Chat UI

import 'package:flutter/material.dart';
import 'src/screens/messages_screen_fixed.dart';

void main() {
  runApp(const MessagesChatDemoApp());
}

class MessagesChatDemoApp extends StatelessWidget {
  const MessagesChatDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messages & Chat - Fixed UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),
      home: const MessagesScreenFixed(),
    );
  }
}
