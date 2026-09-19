// lib/test_flat_member_verification.dart
// Test script to verify flat member verification in messages

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/chat_firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const FlatMemberVerificationTestApp());
}

class FlatMemberVerificationTestApp extends StatelessWidget {
  const FlatMemberVerificationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flat Member Verification Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FlatMemberVerificationTestScreen(),
    );
  }
}

class FlatMemberVerificationTestScreen extends StatefulWidget {
  const FlatMemberVerificationTestScreen({super.key});

  @override
  State<FlatMemberVerificationTestScreen> createState() =>
      _FlatMemberVerificationTestScreenState();
}

class _FlatMemberVerificationTestScreenState
    extends State<FlatMemberVerificationTestScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _members = [];
  String _status = 'Ready to test';
  String _details = '';

  Future<void> _testFlatMemberVerification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing flat member verification...';
      _details = '';
      _members = [];
    });

    try {
      print('\n${'=' * 60}');
      print('🧪 FLAT MEMBER VERIFICATION TEST');
      print('=' * 60);

      // Test 1: Fetch flat members
      print('\n📋 Test 1: Fetching flat members...');
      final members = await _chatService.getFlatMembers();

      setState(() {
        _members = members;
      });

      if (members.isEmpty) {
        setState(() {
          _status = '⚠️  No flat members found';
          _details = 'Either you are the only member in your flat, or verification failed.';
        });
        print('⚠️  No flat members found');
      } else {
        setState(() {
          _status = '✅ Found ${members.length} verified flat member(s)';
          _details = 'All members passed flatId, flatLabel, and adminId verification.';
        });
        print('✅ Found ${members.length} verified flat member(s)');
        
        // Display member details
        print('\n📊 Verified Flat Members:');
        for (var i = 0; i < members.length; i++) {
          final member = members[i];
          print('\n${i + 1}. ${member['name']}');
          print('   - ID: ${member['id']}');
          print('   - Email: ${member['email']}');
          print('   - Phone: ${member['phone']}');
          print('   - Flat ID: ${member['flatId']}');
          print('   - Flat Label: ${member['flatLabel']}');
          print('   - Admin ID: ${member['adminId']}');
          print('   - Role: ${member['role']}');
        }
      }

      print('\n${'=' * 60}');
      print('✅ TEST COMPLETED');
      print('=' * 60 + '\n');
    } catch (e) {
      setState(() {
        _status = '❌ Test failed';
        _details = 'Error: $e';
      });
      print('❌ Test failed: $e');
      print('   Error details: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flat Member Verification Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Test Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This test verifies the flat member verification system:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Fetches users from Firestore "users" collection',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Verifies flatId matches',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Verifies flatLabel matches (if available)',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Verifies adminId matches (if available)',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Excludes current user',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFlatMemberVerification,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Testing...' : 'Run Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status Card
            Card(
              color: _status.startsWith('✅')
                  ? Colors.green.shade50
                  : _status.startsWith('❌')
                      ? Colors.red.shade50
                      : _status.startsWith('⚠️')
                          ? Colors.orange.shade50
                          : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_details.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _details,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Members List
            if (_members.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Flat Members (${_members.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._members.map((member) => _buildMemberCard(member)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Instructions Card
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lightbulb_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Check Console',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View detailed logs in the console/terminal for:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• User authentication flow',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Flat member verification process',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Individual member verification results',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  (member['name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      member['email'] ?? 'No email',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          _buildInfoRow('Flat ID', member['flatId']),
          _buildInfoRow('Flat Label', member['flatLabel']),
          _buildInfoRow('Admin ID', member['adminId']),
          _buildInfoRow('Role', member['role']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
