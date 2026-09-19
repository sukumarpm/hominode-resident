// lib/test_messaging_system.dart
// Test script for real-time messaging system

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/chat_firestore_service.dart';
import 'src/services/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MessagingSystemTestApp());
}

class MessagingSystemTestApp extends StatelessWidget {
  const MessagingSystemTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging System Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MessagingSystemTestScreen(),
    );
  }
}

class MessagingSystemTestScreen extends StatefulWidget {
  const MessagingSystemTestScreen({super.key});

  @override
  State<MessagingSystemTestScreen> createState() => _MessagingSystemTestScreenState();
}

class _MessagingSystemTestScreenState extends State<MessagingSystemTestScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  final UserDataService _userService = UserDataService.instance;
  
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging System Test'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              child: Text(_isRunning ? 'Running Tests...' : 'Run All Tests'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                final isSuccess = result.startsWith('✅');
                final isError = result.startsWith('❌');
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    result,
                    style: TextStyle(
                      color: isSuccess ? Colors.green : (isError ? Colors.red : Colors.black),
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    await _testUserData();
    await _testFlatMembers();
    await _testAdminChat();
    await _testChatRequests();
    await _testChatStreaming();
    await _testMessageOperations();

    setState(() {
      _isRunning = false;
      _testResults.add('\n🎉 All tests completed!');
    });
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  Future<void> _testUserData() async {
    _addResult('\n📋 Test 1: User Data');
    
    try {
      final userData = await _userService.getCurrentUserData();
      
      if (userData == null) {
        _addResult('❌ No user logged in');
        return;
      }
      
      _addResult('✅ User logged in: ${userData['name']}');
      _addResult('   - UID: ${userData['uid']}');
      _addResult('   - Flat ID: ${userData['flatId']}');
      _addResult('   - Building ID: ${userData['buildingId']}');
      _addResult('   - Role: ${userData['role']}');
    } catch (e) {
      _addResult('❌ Error: $e');
    }
  }

  Future<void> _testFlatMembers() async {
    _addResult('\n📋 Test 2: Flat Members Discovery');
    
    try {
      final members = await _chatService.getFlatMembers();
      
      _addResult('✅ Found ${members.length} flat members');
      
      if (members.isEmpty) {
        _addResult('   ℹ️  No other members in your flat');
      } else {
        for (var member in members.take(5)) {
          _addResult('   - ${member['name']} (${member['id']})');
        }
        if (members.length > 5) {
          _addResult('   ... and ${members.length - 5} more');
        }
      }
    } catch (e) {
      _addResult('❌ Error: $e');
    }
  }

  Future<void> _testAdminChat() async {
    _addResult('\n📋 Test 3: Admin Chat');
    
    try {
      final chatId = await _chatService.getOrCreateAdminChat();
      
      if (chatId == null) {
        _addResult('❌ Failed to create/get admin chat');
        return;
      }
      
      _addResult('✅ Admin chat ID: $chatId');
      
      final chat = await _chatService.getChat(chatId);
      if (chat != null) {
        _addResult('   - Title: ${chat.title}');
        _addResult('   - Subtitle: ${chat.subtitle}');
        _addResult('   - Type: admin');
        _addResult('   - Participants: ${chat.participantIds.length}');
      }
    } catch (e) {
      _addResult('❌ Error: $e');
    }
  }

  Future<void> _testChatRequests() async {
    _addResult('\n📋 Test 4: Chat Requests');
    
    try {
      // Stream incoming requests
      final requestsStream = _chatService.streamIncomingChatRequests();
      
      _addResult('✅ Chat requests stream initialized');
      
      // Listen for 2 seconds
      await for (var requests in requestsStream.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) => sink.close(),
      )) {
        _addResult('   - Received ${requests.length} pending requests');
        
        for (var request in requests.take(3)) {
          _addResult('     • From: ${request.senderName}');
          _addResult('       Status: ${request.status}');
        }
        break;
      }
    } catch (e) {
      _addResult('❌ Error: $e');
    }
  }

  Future<void> _testChatStreaming() async {
    _addResult('\n📋 Test 5: Chat Streaming');
    
    try {
      final chatsStream = _chatService.streamUserChats();
      
      _addResult('✅ Chats stream initialized');
      
      // Listen for 2 seconds
      await for (var chats in chatsStream.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) => sink.close(),
      )) {
        _addResult('   - Received ${chats.length} chats');
        
        for (var chat in chats.take(5)) {
          _addResult('     • ${chat.title}');
          _addResult('       Last: ${chat.lastMessage ?? "No messages"}');
          _addResult('       Unread: ${chat.unreadCount}');
        }
        break;
      }
    } catch (e) {
      _addResult('❌ Error: $e');
    }
  }

  Future<void> _testMessageOperations() async {
    _addResult('\n📋 Test 6: Message Operations');
    
    try {
      // Get admin chat for testing
      final chatId = await _chatService.getOrCreateAdminChat();
      
      if (chatId == null) {
        _addResult('❌ No chat available for testing');
        return;
      }
      
      _addResult('✅ Using chat: $chatId');
      
      // Stream messages
      final messagesStream = _chatService.streamChatMessages(chatId);
      
      await for (var messages in messagesStream.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) => sink.close(),
      )) {
        _addResult('   - Received ${messages.length} messages');
        
        if (messages.isNotEmpty) {
          final lastMessage = messages.last;
          _addResult('     • Last from: ${lastMessage.senderName}');
          _addResult('       Text: ${lastMessage.text}');
          _addResult('       Status: ${lastMessage.status}');
        }
        break;
      }
    } catch (e) {
      _addResult('❌ Error: $e');
    }
  }
}
