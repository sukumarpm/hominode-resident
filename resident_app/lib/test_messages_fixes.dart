// lib/test_messages_fixes.dart
// Test script to verify Messages screen fixes

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'src/services/chat_firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestMessagesFixesApp());
}

class TestMessagesFixesApp extends StatelessWidget {
  const TestMessagesFixesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Messages Fixes',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestMessagesFixesScreen(),
    );
  }
}

class TestMessagesFixesScreen extends StatefulWidget {
  const TestMessagesFixesScreen({super.key});

  @override
  State<TestMessagesFixesScreen> createState() => _TestMessagesFixesScreenState();
}

class _TestMessagesFixesScreenState extends State<TestMessagesFixesScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  bool _isLoading = false;
  String _status = 'Ready to test';
  List<Map<String, dynamic>> _members = [];
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Messages Fixes'),
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
            if (_members.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildMembersList(),
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
            '🧪 Messages Fixes Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Testing flat number display and requests tab',
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
          onPressed: _isLoading ? null : _testFlatNumberDisplay,
          icon: const Icon(Icons.people),
          label: const Text('Test 1: Flat Number Display'),
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
          onPressed: _isLoading ? null : _testRequestsStream,
          icon: const Icon(Icons.inbox),
          label: const Text('Test 2: Requests Stream'),
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
          onPressed: _isLoading ? null : _testBothFeatures,
          icon: const Icon(Icons.check_circle),
          label: const Text('Test All Features'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
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

  Widget _buildMembersList() {
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
              Icon(Icons.people, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Building Members (${_members.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._members.map((member) => _buildMemberCard(member)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final flatNumber = member['flatNumber'] ?? 'N/A';
    final isValidFlatNumber = flatNumber != 'Unknown' && 
                               flatNumber != 'N/A' && 
                               !flatNumber.contains('WDxpsEh6DlqdeN9WsYZ');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValidFlatNumber ? Colors.green.shade300 : Colors.orange.shade300,
        ),
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
                    (member['name'] ?? 'U')[0].toUpperCase(),
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
                      member['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Flat: $flatNumber',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isValidFlatNumber)
                          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600)
                        else
                          Icon(Icons.warning, size: 16, color: Colors.orange.shade600),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Building: ${member['buildingName'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (!isValidFlatNumber)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Flat number not properly set (showing "$flatNumber")',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
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

  Future<void> _testFlatNumberDisplay() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing flat number display...';
      _error = null;
      _members = [];
    });

    try {
      print('\n═══════════════════════════════════════════════════');
      print('🧪 TEST 1: FLAT NUMBER DISPLAY');
      print('═══════════════════════════════════════════════════\n');

      final members = await _chatService.getFlatMembers();

      print('\n📊 Test Results:');
      print('   Members found: ${members.length}');
      
      for (var member in members) {
        final flatNumber = member['flatNumber'];
        print('   - ${member['name']}: Flat $flatNumber');
        
        // Check if flat number is valid
        if (flatNumber == 'Unknown' || flatNumber == 'N/A') {
          print('     ⚠️  Flat number not set properly');
        } else if (flatNumber.toString().contains('WDxpsEh6DlqdeN9WsYZ')) {
          print('     ❌ ERROR: Showing flatId instead of flat number!');
        } else {
          print('     ✅ Flat number looks good');
        }
      }

      setState(() {
        _members = members;
        _status = members.isEmpty 
            ? 'No building members found'
            : 'Found ${members.length} building member(s)';
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

  Future<void> _testRequestsStream() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing requests stream...';
      _error = null;
    });

    try {
      print('\n═══════════════════════════════════════════════════');
      print('🧪 TEST 2: REQUESTS STREAM');
      print('═══════════════════════════════════════════════════\n');

      // Listen to stream for 3 seconds
      final stream = _chatService.streamIncomingChatRequests();
      
      await for (var requests in stream.take(1)) {
        print('📊 Test Results:');
        print('   Requests found: ${requests.length}');
        
        if (requests.isEmpty) {
          print('   ℹ️  No pending requests (this is normal)');
        } else {
          for (var request in requests) {
            print('   - From: ${request.senderName}');
            print('     Status: ${request.status}');
          }
        }

        setState(() {
          _status = requests.isEmpty
              ? 'No pending requests (stream working)'
              : 'Found ${requests.length} request(s)';
          _isLoading = false;
        });

        print('\n✅ Test 2 Complete - Stream is working\n');
        break;
      }
    } catch (e) {
      print('❌ Test 2 Failed: $e');
      
      String errorMessage = e.toString();
      if (errorMessage.contains('index')) {
        errorMessage = 'Missing Firestore index for chatRequests collection';
      }
      
      setState(() {
        _error = 'Requests stream error: $errorMessage';
        _status = 'Test failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _testBothFeatures() async {
    await _testFlatNumberDisplay();
    await Future.delayed(const Duration(seconds: 1));
    await _testRequestsStream();
  }
}
