// lib/test_flat_members_fix.dart
// Test the updated getFlatMembers() method

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/chat_firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestFlatMembersApp());
}

class TestFlatMembersApp extends StatelessWidget {
  const TestFlatMembersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Flat Members',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestFlatMembersScreen(),
    );
  }
}

class TestFlatMembersScreen extends StatefulWidget {
  const TestFlatMembersScreen({super.key});

  @override
  State<TestFlatMembersScreen> createState() => _TestFlatMembersScreenState();
}

class _TestFlatMembersScreenState extends State<TestFlatMembersScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  
  String _output = 'Tap "Test Flat Members" to start';
  bool _isLoading = false;
  List<Map<String, dynamic>> _members = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Flat Members'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          // Output log
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  if (_members.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Flat Members UI Preview:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._members.map((member) => _buildMemberCard(member)),
                  ],
                ],
              ),
            ),
          ),
          
          // Test button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testFlatMembers,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF2563EB),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Test Flat Members',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testFlatMembers() async {
    setState(() {
      _isLoading = true;
      _output = 'Testing flat members fetch...\n\n';
      _members = [];
    });

    try {
      final members = await _chatService.getFlatMembers();
      
      setState(() {
        _members = members;
        _output += '\n═══════════════════════════════════════════════════\n';
        _output += '✅ TEST COMPLETE\n';
        _output += '═══════════════════════════════════════════════════\n\n';
        
        if (members.isEmpty) {
          _output += '❌ No flat members found\n\n';
          _output += '💡 This means:\n';
          _output += '   - No other users have the same flatId + buildingId\n';
          _output += '   - You need to add more users to Firestore\n';
        } else {
          _output += '✅ Found ${members.length} flat member(s)\n\n';
          _output += 'Members will appear in UI below.\n';
        }
      });
    } catch (e) {
      setState(() {
        _output += '\n❌ ERROR: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final memberName = member['name'] ?? 'Unknown';
    final flatNumber = member['flatNumber'] ?? 'N/A';
    final photoUrl = member['photoUrl'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          memberName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      memberName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Flat $flatNumber',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Arrow icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}
