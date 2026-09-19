// lib/diagnose_chat_requests_now.dart
// Diagnostic script to check chat requests flow

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DiagnoseChatRequestsApp());
}

class DiagnoseChatRequestsApp extends StatelessWidget {
  const DiagnoseChatRequestsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnose Chat Requests',
      home: const DiagnoseChatRequestsScreen(),
    );
  }
}

class DiagnoseChatRequestsScreen extends StatefulWidget {
  const DiagnoseChatRequestsScreen({super.key});

  @override
  State<DiagnoseChatRequestsScreen> createState() => _DiagnoseChatRequestsScreenState();
}

class _DiagnoseChatRequestsScreenState extends State<DiagnoseChatRequestsScreen> {
  String _output = 'Ready to diagnose...';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnose Chat Requests'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _diagnose,
              child: const Text('Run Diagnosis'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _diagnose() async {
    setState(() {
      _isLoading = true;
      _output = 'Running diagnosis...\n\n';
    });

    final buffer = StringBuffer();
    
    try {
      buffer.writeln('═══════════════════════════════════════════════════');
      buffer.writeln('🔍 CHAT REQUESTS DIAGNOSIS');
      buffer.writeln('═══════════════════════════════════════════════════\n');

      // STEP 1: Get Firebase Auth user
      buffer.writeln('📋 STEP 1: Get Firebase Auth User');
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser == null) {
        buffer.writeln('❌ No Firebase Auth user logged in');
        setState(() {
          _output = buffer.toString();
          _isLoading = false;
        });
        return;
      }
      
      final authUid = firebaseUser.uid;
      buffer.writeln('✅ Firebase Auth UID: $authUid');
      buffer.writeln('   Email: ${firebaseUser.email}\n');

      // STEP 2: Find user document by authUid
      buffer.writeln('📋 STEP 2: Find User Document by authUid');
      buffer.writeln('🔍 Query: users.where("authUid", isEqualTo: "$authUid")');
      
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUid', isEqualTo: authUid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isEmpty) {
        buffer.writeln('❌ User document not found for authUid: $authUid');
        setState(() {
          _output = buffer.toString();
          _isLoading = false;
        });
        return;
      }
      
      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data();
      
      buffer.writeln('✅ User Document Found:');
      buffer.writeln('   Document ID: $userId');
      buffer.writeln('   Name: ${userData['name']}');
      buffer.writeln('   Email: ${userData['email']}');
      buffer.writeln('   authUid: ${userData['authUid']}\n');

      // STEP 3: Query chat requests by receiverId
      buffer.writeln('📋 STEP 3: Query Chat Requests');
      buffer.writeln('🔍 Query: chatRequests.where("receiverId", isEqualTo: "$userId")');
      
      final requestsQuery = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('receiverId', isEqualTo: userId)
          .get();
      
      buffer.writeln('📊 Total requests found: ${requestsQuery.docs.length}\n');
      
      if (requestsQuery.docs.isEmpty) {
        buffer.writeln('ℹ️  No chat requests found for this user');
      } else {
        for (var doc in requestsQuery.docs) {
          final data = doc.data();
          buffer.writeln('📄 Request Document: ${doc.id}');
          buffer.writeln('   senderId: ${data['senderId']}');
          buffer.writeln('   senderName: ${data['senderName']}');
          buffer.writeln('   receiverId: ${data['receiverId']}');
          buffer.writeln('   receiverName: ${data['receiverName']}');
          buffer.writeln('   status: ${data['status']}');
          buffer.writeln('   flatId: ${data['flatId']}');
          buffer.writeln('   createdAt: ${data['createdAt']}\n');
        }
      }

      // STEP 4: Filter pending requests
      buffer.writeln('📋 STEP 4: Filter Pending Requests');
      final pendingRequests = requestsQuery.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .toList();
      
      buffer.writeln('📊 Pending requests: ${pendingRequests.length}\n');
      
      if (pendingRequests.isEmpty) {
        buffer.writeln('ℹ️  No pending requests');
      } else {
        buffer.writeln('✅ Pending Requests:');
        for (var doc in pendingRequests) {
          final data = doc.data();
          buffer.writeln('   - From: ${data['senderName']}');
          buffer.writeln('     Status: ${data['status']}');
        }
      }

      // STEP 5: Test stream query
      buffer.writeln('\n📋 STEP 5: Test Stream Query');
      buffer.writeln('🔍 Query: chatRequests');
      buffer.writeln('   .where("receiverId", isEqualTo: "$userId")');
      buffer.writeln('   .where("status", isEqualTo: "pending")');
      buffer.writeln('   .orderBy("createdAt", descending: true)');
      
      try {
        final streamQuery = await FirebaseFirestore.instance
            .collection('chatRequests')
            .where('receiverId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        buffer.writeln('✅ Stream query works! Found ${streamQuery.docs.length} document(s)');
      } catch (e) {
        buffer.writeln('❌ Stream query error: $e');
        if (e.toString().contains('index')) {
          buffer.writeln('\n⚠️  FIRESTORE INDEX MISSING!');
          buffer.writeln('   Create composite index:');
          buffer.writeln('   Collection: chatRequests');
          buffer.writeln('   Fields:');
          buffer.writeln('     - receiverId (Ascending)');
          buffer.writeln('     - status (Ascending)');
          buffer.writeln('     - createdAt (Descending)');
        }
      }

      buffer.writeln('\n═══════════════════════════════════════════════════');
      buffer.writeln('✅ DIAGNOSIS COMPLETE');
      buffer.writeln('═══════════════════════════════════════════════════');

    } catch (e) {
      buffer.writeln('\n❌ ERROR: $e');
      buffer.writeln('Stack trace: ${StackTrace.current}');
    }

    setState(() {
      _output = buffer.toString();
      _isLoading = false;
    });
    
    print(_output);
  }
}
