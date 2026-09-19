// lib/test_chat_firestore.dart
// Test script for chat Firestore integration

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/chat_firestore_service.dart';
import 'src/models/chat_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const ChatFirestoreTestApp());
}

class ChatFirestoreTestApp extends StatelessWidget {
  const ChatFirestoreTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Firestore Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatFirestoreTestScreen(),
    );
  }
}

class ChatFirestoreTestScreen extends StatefulWidget {
  const ChatFirestoreTestScreen({super.key});

  @override
  State<ChatFirestoreTestScreen> createState() => _ChatFirestoreTestScreenState();
}

class _ChatFirestoreTestScreenState extends State<ChatFirestoreTestScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  bool _isLoading = false;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _log(String message) {
    setState(() {
      _output += '$message\n';
    });
    print(message);
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    _log('🧪 CHAT FIRESTORE TEST');
    _log('=' * 50);
    _log('');

    // Test 1: Create a test chat
    _log('📋 Test 1: Create Test Chat');
    _log('-' * 50);
    try {
      final chatId = await _chatService.createChat(
        title: 'Test Chat',
        subtitle: 'Testing chat functionality',
        participantIds: [], // Will add current user automatically
        isGroup: false,
        iconName: 'chat_bubble',
        iconBg: '#2563EB',
      );

      if (chatId != null) {
        _log('✅ Chat created successfully');
        _log('   Chat ID: $chatId');
        
        // Test 2: Send a test message
        _log('');
        _log('📋 Test 2: Send Test Message');
        _log('-' * 50);
        
        final messageId = await _chatService.sendMessage(
          chatId: chatId,
          text: 'Hello! This is a test message.',
        );

        if (messageId != null) {
          _log('✅ Message sent successfully');
          _log('   Message ID: $messageId');
        } else {
          _log('❌ Failed to send message');
        }
      } else {
        _log('❌ Failed to create chat');
      }
    } catch (e) {
      _log('❌ Error: $e');
    }
    _log('');

    // Test 3: Stream chats
    _log('📋 Test 3: Stream User Chats');
    _log('-' * 50);
    _log('   Listening for real-time updates...');
    _log('   (Check console and stream section below)');
    _log('');

    // Test 4: Summary
    _log('📋 Test Summary');
    _log('=' * 50);
    _log('✅ All tests completed');
    _log('');
    _log('📝 Notes:');
    _log('   - Chats are stored in "chats" collection');
    _log('   - Messages are in "chats/{chatId}/messages" subcollection');
    _log('   - Real-time streaming is enabled');
    _log('   - All data is fetched from Firestore');
    _log('');
    _log('🔄 To test real-time updates:');
    _log('   1. Keep this screen open');
    _log('   2. Add/update chats in Firestore');
    _log('   3. Watch the stream section below');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Firestore Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
            tooltip: 'Rerun Tests',
          ),
        ],
      ),
      body: Column(
        children: [
          // Test output
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ),
          
          // Real-time stream section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stream, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Real-Time Chat Stream',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<ChatModel>>(
                  stream: _chatService.streamUserChats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Connecting to stream...'),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      );
                    }

                    final chats = snapshot.data ?? [];

                    if (chats.isEmpty) {
                      return const Text('No chats found');
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${chats.length} chat(s) found',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...chats.map((chat) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${chat.title} - ${chat.lastMessage ?? "No messages"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
