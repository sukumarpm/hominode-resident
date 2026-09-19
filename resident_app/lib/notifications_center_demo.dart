// lib/notifications_center_demo.dart
// Demo app for Notifications Center screen

import 'package:flutter/material.dart';
import 'src/screens/notifications_center_screen.dart';

void main() {
  runApp(const NotificationsCenterDemoApp());
}

class NotificationsCenterDemoApp extends StatelessWidget {
  const NotificationsCenterDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notifications Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),
      home: const NotificationsCenterScreen(),
    );
  }
}
