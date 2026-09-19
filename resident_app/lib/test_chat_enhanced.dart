// lib/test_chat_enhanced.dart
// Test script for enhanced chat system

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'src/services/chat_firestore_service.dart';
import 'src/services/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ChatTestApp());
}

class ChatTestApp extends StatelessWidget {
  const ChatTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Enhanced Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatTestScreen(),
    );
  }
}

class ChatTestScreen extends StatefulWidget {
  const ChatTestScreen({super.key});

  @override
  State<ChatTestScreen> createState() => _ChatTestScreenState();
}

class _ChatTestScreenState extends State<ChatTestScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  final UserDataService _userDataService = UserDataService.instance;
  
  bool _isLoading = false;
  String _status = 'Ready to test';
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _flatMembers = [];
  int _chatCount = 0;
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading user data...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = '❌ No user logged in';
          _isLoading = false;
        });
        return;
      }

      final userData = await _userDataService.getCurrentUserData();
      
      setState(() {
        _userData = userData;
        _status = '✅ User loaded: ${userData?['name'] ?? 'Unknown'}';
        _isLoading = false;
      });

      print('✅ User Data: $userData');
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetFlatMembers() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching flat members...';
    });

    try {
      final members = await _chatService.getFlatMembers();
      
      setState(() {
        _flatMembers = members;
        _status = '✅ Found ${members.length} flat members';
        _isLoading = false;
      });

      print('✅ Flat Members:');
      for (var member in members) {
        print('   - ${member['name']} (${member['flatLabel'] ?? member['flatId']})');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testStreamChats() async {
    setState(() {
      _isLoading = true;
      _status = 'Streaming chats...';
    });

    try {
      _chatService.streamUserChats().listen((chats) {
        setState(() {
          _chatCount = chats.length;
          _status = '✅ Streaming ${chats.length} chats';
          _isLoading = false;
        });

        print('✅ Chats:');
        for (var chat in chats) {
          print('   - ${chat.title}: ${chat.lastMessage ?? 'No messages'}');
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testStreamRequests() async {
    setState(() {
      _isLoading = true;
      _status = 'Streaming chat requests...';
    });

    try {
      _chatService.streamIncomingChatRequests().listen((requests) {
        setState(() {
          _requestCount = requests.length;
          _status = '✅ Streaming ${requests.length} requests';
          _isLoading = false;
        });

        print('✅ Chat Requests:');
        for (var request in requests) {
          print('   - From: ${request.senderName} (${request.status})');
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSendRequest() async {
    if (_flatMembers.isEmpty) {
      setState(() {
        _status = '⚠️  No flat members. Fetch members first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Sending chat request...';
    });

    try {
      final member = _flatMembers.first;
      final requestId = await _chatService.sendChatRequest(
        toUserId: member['id'],
        toUserName: member['name'] ?? 'Unknown',
        message: 'Hi! I would like to chat with you.',
      );

      setState(() {
        _status = requestId != null
            ? '✅ Request sent to ${member['name']}'
            : '❌ Failed to send request';
        _isLoading = false;
      });

      print('✅ Request ID: $requestId');
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateAdminChat() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating admin chat...';
    });

    try {
      final chatId = await _chatService.getOrCreateAdminChat();

      setState(() {
        _status = chatId != null
            ? '✅ Admin chat created/found: $chatId'
            : '❌ Failed to create admin chat';
        _isLoading = false;
      });

      print('✅ Admin Chat ID: $chatId');
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Enhanced Test'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User Info Card
            if (_userData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Name: ${_userData!['name'] ?? 'Unknown'}'),
                      Text('Flat: ${_userData!['flatLabel'] ?? _userData!['flatId'] ?? 'Unknown'}'),
                      Text('Building: ${_userData!['buildingId'] ?? 'Unknown'}'),
                      Text('Role: ${_userData!['role'] ?? 'Unknown'}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Flat Members: ${_flatMembers.length}'),
                    Text('Active Chats: $_chatCount'),
                    Text('Pending Requests: $_requestCount'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Buttons
            const Text(
              'Test Functions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetFlatMembers,
              icon: const Icon(Icons.people),
              label: const Text('Get Flat Members'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testStreamChats,
              icon: const Icon(Icons.chat),
              label: const Text('Stream Chats'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testStreamRequests,
              icon: const Icon(Icons.inbox),
              label: const Text('Stream Chat Requests'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSendRequest,
              icon: const Icon(Icons.send),
              label: const Text('Send Chat Request (to first member)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCreateAdminChat,
              icon: const Icon(Icons.support_agent),
              label: const Text('Create/Get Admin Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
              ),
            ),

            const SizedBox(height: 24),

            // Flat Members List
            if (_flatMembers.isNotEmpty) ...[
              const Text(
                'Flat Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._flatMembers.map((member) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      (member['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(member['name'] ?? 'Unknown'),
                  subtitle: Text('Flat ${member['flatLabel'] ?? member['flatId'] ?? 'Unknown'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                        _status = 'Sending request to ${member['name']}...';
                      });

                      final requestId = await _chatService.sendChatRequest(
                        toUserId: member['id'],
                        toUserName: member['name'] ?? 'Unknown',
                        message: 'Hi! I would like to chat with you.',
                      );

                      setState(() {
                        _status = requestId != null
                            ? '✅ Request sent to ${member['name']}'
                            : '❌ Failed to send request';
                        _isLoading = false;
                      });
                    },
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
