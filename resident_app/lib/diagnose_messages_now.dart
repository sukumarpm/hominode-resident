// Diagnose Messages Screen Issues
// Run this to see what's happening

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'src/services/firestore_auth_service.dart';
import 'src/services/chat_firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DiagnoseMessagesApp());
}

class DiagnoseMessagesApp extends StatelessWidget {
  const DiagnoseMessagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnose Messages',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _authService = FirestoreAuthService.instance;
  final _chatService = ChatFirestoreService.instance;
  
  String _output = '';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  void _log(String message) {
    setState(() {
      _output += '$message\n';
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _output = '';
    });

    _log('========================================');
    _log('🔍 MESSAGES SCREEN DIAGNOSTICS');
    _log('========================================\n');

    // Step 1: Check Firebase Auth
    _log('Step 1: Checking Firebase Auth...');
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _log('✅ Firebase Auth: Signed in');
      _log('   UID: ${firebaseUser.uid}');
      _log('   Email: ${firebaseUser.email}');
    } else {
      _log('⚠️  Firebase Auth: Not signed in');
    }
    _log('');

    // Step 2: Check Firestore Auth
    _log('Step 2: Checking Firestore Auth...');
    final isLoggedIn = await _authService.isLoggedIn();
    final userId = await _authService.getCurrentUserId();
    
    if (isLoggedIn && userId != null) {
      _log('✅ Firestore Auth: Logged in');
      _log('   User ID: $userId');
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _log('   Name: ${userData['name']}');
        _log('   Email: ${userData['email']}');
        _log('   Phone: ${userData['phone']}');
        _log('   Building ID: ${userData['buildingId']}');
        _log('   Flat ID: ${userData['flatId']}');
        _log('   authUid: ${userData['authUid'] ?? 'NOT SET'}');
      }
    } else {
      _log('❌ Firestore Auth: Not logged in');
      _log('   Need to login first!');
    }
    _log('');

    // Step 3: Test Chat Service User ID
    _log('Step 3: Testing Chat Service...');
    try {
      // This will trigger the _getCurrentUserId method
      final chatsStream = _chatService.streamUserChats();
      _log('✅ Chat service initialized');
      _log('   Check console for user ID logs');
    } catch (e) {
      _log('❌ Chat service error: $e');
    }
    _log('');

    // Step 4: Check Chats Collection
    _log('Step 4: Checking Chats Collection...');
    if (userId != null) {
      try {
        final chatsQuery = await _firestore
            .collection('chats')
            .where('participantIds', arrayContains: userId)
            .get();
        
        _log('✅ Chats query successful');
        _log('   Found ${chatsQuery.docs.length} chats');
        
        if (chatsQuery.docs.isEmpty) {
          _log('   No chats exist for this user');
        }
      } catch (e) {
        _log('❌ Chats query error: $e');
      }
    }
    _log('');

    // Step 5: Check Chat Requests Collection
    _log('Step 5: Checking Chat Requests...');
    if (userId != null) {
      try {
        final requestsQuery = await _firestore
            .collection('chatRequests')
            .where('toUserId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();
        
        _log('✅ Chat requests query successful');
        _log('   Found ${requestsQuery.docs.length} requests');
      } catch (e) {
        _log('❌ Chat requests query error: $e');
      }
    }
    _log('');

    // Step 6: Check Flat Members
    _log('Step 6: Checking Flat Members...');
    if (userId != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final buildingId = userData['buildingId'];
          
          if (buildingId != null) {
            // Get flats in building
            final flatsQuery = await _firestore
                .collection('flats')
                .where('buildingId', isEqualTo: buildingId)
                .get();
            
            _log('✅ Found ${flatsQuery.docs.length} flats in building');
            
            // Get users in those flats
            final flatIds = flatsQuery.docs.map((doc) => doc.id).toList();
            
            if (flatIds.isNotEmpty) {
              // Take first 10 flat IDs
              final batch = flatIds.take(10).toList();
              
              final usersQuery = await _firestore
                  .collection('users')
                  .where('flatId', whereIn: batch)
                  .where('role', isEqualTo: 'resident')
                  .get();
              
              _log('✅ Found ${usersQuery.docs.length} residents');
              
              // Count excluding current user
              int otherUsers = 0;
              for (var doc in usersQuery.docs) {
                if (doc.id != userId) {
                  otherUsers++;
                  _log('   - ${doc.data()['name']} (${doc.id})');
                }
              }
              
              _log('   Total other residents: $otherUsers');
              
              if (otherUsers == 0) {
                _log('   ⚠️  No other residents found!');
                _log('   This is why flat members shows only you');
              }
            }
          } else {
            _log('❌ No building ID found');
          }
        }
      } catch (e) {
        _log('❌ Flat members error: $e');
      }
    }
    _log('');

    _log('========================================');
    _log('DIAGNOSIS COMPLETE');
    _log('========================================');
    _log('');
    _log('SUMMARY:');
    if (firebaseUser == null && userId == null) {
      _log('❌ NOT LOGGED IN - Login first!');
    } else if (firebaseUser == null && userId != null) {
      _log('⚠️  Firestore Auth only (no Firebase Auth)');
      _log('   This is causing the error!');
      _log('   Solution: Restart the app to apply fix');
    } else {
      _log('✅ Authentication OK');
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunning ? null : _runDiagnostics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isRunning)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              SelectableText(
                _output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
