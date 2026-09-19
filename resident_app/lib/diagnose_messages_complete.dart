// lib/diagnose_messages_complete.dart
// Complete diagnostic for Messages feature (Chats + Requests)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DiagnoseMessagesApp());
}

class DiagnoseMessagesApp extends StatelessWidget {
  const DiagnoseMessagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnose Messages Complete',
      home: const DiagnoseMessagesScreen(),
    );
  }
}

class DiagnoseMessagesScreen extends StatefulWidget {
  const DiagnoseMessagesScreen({super.key});

  @override
  State<DiagnoseMessagesScreen> createState() => _DiagnoseMessagesScreenState();
}

class _DiagnoseMessagesScreenState extends State<DiagnoseMessagesScreen> {
  String _output = 'Ready to diagnose Messages feature...';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnose Messages Complete'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _diagnose,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Run Complete Diagnosis', style: TextStyle(fontSize: 16)),
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
      _output = 'Running complete diagnosis...\n\n';
    });

    final buffer = StringBuffer();
    final stopwatch = Stopwatch()..start();
    
    try {
      buffer.writeln('═══════════════════════════════════════════════════');
      buffer.writeln('🔍 MESSAGES FEATURE COMPLETE DIAGNOSIS');
      buffer.writeln('═══════════════════════════════════════════════════\n');

      // STEP 1: Get Firebase Auth user
      buffer.writeln('📋 STEP 1: Get Firebase Auth User');
      final step1Start = stopwatch.elapsedMilliseconds;
      
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
      final step1Time = stopwatch.elapsedMilliseconds - step1Start;
      buffer.writeln('✅ Firebase Auth UID: $authUid');
      buffer.writeln('   Email: ${firebaseUser.email}');
      buffer.writeln('   ⏱️  Time: ${step1Time}ms\n');

      // STEP 2: Find user document by authUid
      buffer.writeln('📋 STEP 2: Find User Document by authUid');
      final step2Start = stopwatch.elapsedMilliseconds;
      
      buffer.writeln('🔍 Query: users.where("authUid", isEqualTo: "$authUid")');
      
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUid', isEqualTo: authUid)
          .limit(1)
          .get();
      
      final step2Time = stopwatch.elapsedMilliseconds - step2Start;
      
      if (userQuery.docs.isEmpty) {
        buffer.writeln('❌ User document not found for authUid: $authUid');
        buffer.writeln('   ⏱️  Time: ${step2Time}ms\n');
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
      buffer.writeln('   authUid: ${userData['authUid']}');
      buffer.writeln('   ⏱️  Time: ${step2Time}ms\n');

      // STEP 3: Query chat requests
      buffer.writeln('📋 STEP 3: Query Chat Requests');
      final step3Start = stopwatch.elapsedMilliseconds;
      
      buffer.writeln('🔍 Query: chatRequests.where("receiverId", isEqualTo: "$userId")');
      
      final requestsQuery = await FirebaseFirestore.instance
          .collection('chatRequests')
          .where('receiverId', isEqualTo: userId)
          .get();
      
      final step3Time = stopwatch.elapsedMilliseconds - step3Start;
      
      buffer.writeln('📊 Total requests found: ${requestsQuery.docs.length}');
      buffer.writeln('   ⏱️  Time: ${step3Time}ms\n');
      
      if (requestsQuery.docs.isNotEmpty) {
        for (var doc in requestsQuery.docs) {
          final data = doc.data();
          buffer.writeln('📄 Request: ${doc.id}');
          buffer.writeln('   From: ${data['senderName']}');
          buffer.writeln('   Status: ${data['status']}\n');
        }
      }

      // STEP 4: Query chats
      buffer.writeln('📋 STEP 4: Query Chats');
      final step4Start = stopwatch.elapsedMilliseconds;
      
      buffer.writeln('🔍 Query: chats.where("participants", arrayContains: "$userId")');
      
      final chatsQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
      
      final step4Time = stopwatch.elapsedMilliseconds - step4Start;
      
      buffer.writeln('📊 Total chats found: ${chatsQuery.docs.length}');
      buffer.writeln('   ⏱️  Time: ${step4Time}ms\n');
      
      if (chatsQuery.docs.isNotEmpty) {
        for (var doc in chatsQuery.docs) {
          final data = doc.data();
          buffer.writeln('💬 Chat: ${doc.id}');
          buffer.writeln('   Title: ${data['title']}');
          buffer.writeln('   Type: ${data['type'] ?? 'resident'}');
          buffer.writeln('   Participants: ${data['participants']}\n');
        }
      }

      // STEP 5: Test stream queries
      buffer.writeln('📋 STEP 5: Test Stream Queries');
      
      // Test requests stream
      buffer.writeln('\n🔍 Testing Requests Stream:');
      final step5aStart = stopwatch.elapsedMilliseconds;
      
      try {
        final requestsStreamQuery = await FirebaseFirestore.instance
            .collection('chatRequests')
            .where('receiverId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        final step5aTime = stopwatch.elapsedMilliseconds - step5aStart;
        buffer.writeln('✅ Requests stream query works!');
        buffer.writeln('   Found: ${requestsStreamQuery.docs.length} pending request(s)');
        buffer.writeln('   ⏱️  Time: ${step5aTime}ms');
      } catch (e) {
        final step5aTime = stopwatch.elapsedMilliseconds - step5aStart;
        buffer.writeln('❌ Requests stream error: $e');
        buffer.writeln('   ⏱️  Time: ${step5aTime}ms');
        if (e.toString().contains('index')) {
          buffer.writeln('\n⚠️  FIRESTORE INDEX MISSING FOR REQUESTS!');
          buffer.writeln('   Collection: chatRequests');
          buffer.writeln('   Fields: receiverId (Asc), status (Asc), createdAt (Desc)');
        }
      }

      // Test chats stream
      buffer.writeln('\n🔍 Testing Chats Stream:');
      final step5bStart = stopwatch.elapsedMilliseconds;
      
      try {
        final chatsStreamQuery = await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: userId)
            .orderBy('updatedAt', descending: true)
            .limit(1)
            .get();
        
        final step5bTime = stopwatch.elapsedMilliseconds - step5bStart;
        buffer.writeln('✅ Chats stream query works!');
        buffer.writeln('   Found: ${chatsStreamQuery.docs.length} chat(s)');
        buffer.writeln('   ⏱️  Time: ${step5bTime}ms');
      } catch (e) {
        final step5bTime = stopwatch.elapsedMilliseconds - step5bStart;
        buffer.writeln('❌ Chats stream error: $e');
        buffer.writeln('   ⏱️  Time: ${step5bTime}ms');
        if (e.toString().contains('index')) {
          buffer.writeln('\n⚠️  FIRESTORE INDEX MISSING FOR CHATS!');
          buffer.writeln('   Collection: chats');
          buffer.writeln('   Fields: participants (Array), updatedAt (Desc)');
        }
      }

      stopwatch.stop();
      
      buffer.writeln('\n═══════════════════════════════════════════════════');
      buffer.writeln('✅ DIAGNOSIS COMPLETE');
      buffer.writeln('═══════════════════════════════════════════════════');
      buffer.writeln('\n📊 PERFORMANCE SUMMARY:');
      buffer.writeln('   Total Time: ${stopwatch.elapsedMilliseconds}ms');
      buffer.writeln('   Step 1 (Auth): ${step1Time}ms');
      buffer.writeln('   Step 2 (User Doc): ${step2Time}ms');
      buffer.writeln('   Step 3 (Requests): ${step3Time}ms');
      buffer.writeln('   Step 4 (Chats): ${step4Time}ms');
      
      if (stopwatch.elapsedMilliseconds > 1000) {
        buffer.writeln('\n⚠️  SLOW PERFORMANCE DETECTED!');
        buffer.writeln('   Total time > 1 second');
        buffer.writeln('   Check Firestore indexes and network connection');
      } else {
        buffer.writeln('\n✅ GOOD PERFORMANCE!');
        buffer.writeln('   All queries completed in < 1 second');
      }

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
