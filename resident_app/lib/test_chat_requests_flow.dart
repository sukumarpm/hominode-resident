// lib/test_chat_requests_flow.dart
// Test script to verify chat requests flow

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'src/services/chat_firestore_service.dart';
import 'src/models/chat_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestChatRequestsApp());
}

class TestChatRequestsApp extends StatelessWidget {
  const TestChatRequestsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Chat Requests Flow',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestChatRequestsScreen(),
    );
  }
}

class TestChatRequestsScreen extends StatefulWidget {
  const TestChatRequestsScreen({super.key});

  @override
  State<TestChatRequestsScreen> createState() => _TestChatRequestsScreenState();
}

class _TestChatRequestsScreenState extends State<TestChatRequestsScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  bool _isLoading = false;
  String _status = 'Ready to test';
  List<ChatRequestModel> _requests = [];
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Chat Requests Flow'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCurrentUserInfo(),
            const SizedBox(height: 20),
            _buildTestButtons(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            if (_requests.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildRequestsList(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '🧪 Chat Requests Flow Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Testing fetch and accept flow',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Current User',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user != null) ...[
            _buildInfoRow('UID', user.uid),
            _buildInfoRow('Email', user.email ?? 'N/A'),
          ] else
            const Text(
              'No user logged in',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testFetchRequests,
          icon: const Icon(Icons.inbox),
          label: const Text('Test 1: Fetch Chat Requests'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testStreamRequests,
          icon: const Icon(Icons.stream),
          label: const Text('Test 2: Stream Chat Requests (Realtime)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading || _requests.isEmpty ? null : () => _testAcceptRequest(_requests.first),
          icon: const Icon(Icons.check_circle),
          label: const Text('Test 3: Accept First Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _testDirectFirestoreQuery,
          icon: const Icon(Icons.search),
          label: const Text('Test 4: Direct Firestore Query'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isLoading ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLoading ? Colors.blue.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.info_outline,
              color: Colors.green.shade700,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 14,
                color: _isLoading ? Colors.blue.shade900 : Colors.green.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Chat Requests (${_requests.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._requests.map((request) => _buildRequestCard(request)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ChatRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    request.senderName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.senderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: ${request.status.toString().split('.').last}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Request ID: ${request.id}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Sender ID: ${request.senderId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Receiver ID: ${request.receiverId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Flat ID: ${request.flatId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testFetchRequests() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching chat requests...';
      _error = null;
      _requests = [];
    });

    try {
      print('\n═══════════════════════════════════════════════════');
      print('🧪 TEST 1: FETCH CHAT REQUESTS');
      print('═══════════════════════════════════════════════════\n');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      print('📋 Current User: ${user.uid}');

      // Query Firestore directly
      final snapshot = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      print('📊 Found ${snapshot.docs.length} chat request(s)\n');

      final requests = snapshot.docs.map((doc) {
        print('📄 Request Document:');
        print('   ID: ${doc.id}');
        print('   Data: ${doc.data()}');
        return ChatRequestModel.fromFirestore(doc);
      }).toList();

      setState(() {
        _requests = requests;
        _status = requests.isEmpty
            ? 'No pending requests found'
            : 'Found ${requests.length} request(s)';
        _isLoading = false;
      });

      print('\n✅ Test 1 Complete\n');
    } catch (e) {
      print('❌ Test 1 Failed: $e');
      setState(() {
        _error = 'Test failed: $e';
        _status = 'Test failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _testStreamRequests() async {
    setState(() {
      _isLoading = true;
      _status = 'Streaming chat requests...';
      _error = null;
    });

    try {
      print('\n═══════════════════════════════════════════════════');
      print('🧪 TEST 2: STREAM CHAT REQUESTS');
      print('═══════════════════════════════════════════════════\n');

      final stream = _chatService.streamIncomingChatRequests();
      
      await for (var requests in stream.take(1)) {
        print('📊 Received ${requests.length} request(s) from stream\n');
        
        for (var request in requests) {
          print('📄 Request:');
          print('   From: ${request.senderName}');
          print('   Status: ${request.status}');
          print('   ID: ${request.id}');
        }

        setState(() {
          _requests = requests;
          _status = requests.isEmpty
              ? 'No pending requests (stream working)'
              : 'Found ${requests.length} request(s) via stream';
          _isLoading = false;
        });

        print('\n✅ Test 2 Complete - Stream is working\n');
        break;
      }
    } catch (e) {
      print('❌ Test 2 Failed: $e');
      setState(() {
        _error = 'Stream test failed: $e';
        _status = 'Test failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAcceptRequest(ChatRequestModel request) async {
    setState(() {
      _isLoading = true;
      _status = 'Accepting request...';
      _error = null;
    });

    try {
      print('\n═══════════════════════════════════════════════════');
      print('🧪 TEST 3: ACCEPT CHAT REQUEST');
      print('═══════════════════════════════════════════════════\n');

      print('📋 Accepting request from: ${request.senderName}');
      print('   Request ID: ${request.id}');

      final chatId = await _chatService.acceptChatRequest(request.id);

      if (chatId != null) {
        print('✅ Request accepted!');
        print('   Chat ID: $chatId');
        
        // Verify chat was created
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();
        
        if (chatDoc.exists) {
          print('✅ Chat document created successfully');
          print('   Chat data: ${chatDoc.data()}');
        } else {
          print('⚠️  Chat document not found');
        }

        setState(() {
          _status = 'Request accepted! Chat ID: $chatId';
          _isLoading = false;
        });

        // Refresh requests list
        await _testFetchRequests();
      } else {
        throw Exception('Failed to accept request');
      }

      print('\n✅ Test 3 Complete\n');
    } catch (e) {
      print('❌ Test 3 Failed: $e');
      setState(() {
        _error = 'Accept test failed: $e';
        _status = 'Test failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _testDirectFirestoreQuery() async {
    setState(() {
      _isLoading = true;
      _status = 'Running direct Firestore query...';
      _error = null;
    });

    try {
      print('\n═══════════════════════════════════════════════════');
      print('🧪 TEST 4: DIRECT FIRESTORE QUERY');
      print('═══════════════════════════════════════════════════\n');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get user document
      print('📋 Step 1: Get user document');
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User document not found');
      }

      final userId = userQuery.docs.first.id;
      print('✅ User ID: $userId\n');

      // Query chat requests
      print('📋 Step 2: Query chat requests');
      print('   Query: chatRequests.where("receiverId", isEqualTo: "$userId")');
      
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('receiverId', isEqualTo: userId)
          .get();

      print('📊 Total requests: ${requestsSnapshot.docs.length}');
      
      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        print('\n📄 Request ${doc.id}:');
        print('   senderId: ${data['senderId']}');
        print('   senderName: ${data['senderName']}');
        print('   receiverId: ${data['receiverId']}');
        print('   status: ${data['status']}');
        print('   flatId: ${data['flatId']}');
      }

      // Filter pending only
      final pendingRequests = requestsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .toList();

      print('\n📊 Pending requests: ${pendingRequests.length}');

      setState(() {
        _status = 'Found ${requestsSnapshot.docs.length} total, ${pendingRequests.length} pending';
        _isLoading = false;
      });

      print('\n✅ Test 4 Complete\n');
    } catch (e) {
      print('❌ Test 4 Failed: $e');
      setState(() {
        _error = 'Direct query failed: $e';
        _status = 'Test failed';
        _isLoading = false;
      });
    }
  }
}
