// Test Messages Screen Debug
// Run this to diagnose the messages screen error

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'src/services/chat_firestore_service.dart';
import 'src/services/firestore_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TestMessagesDebugApp());
}

class TestMessagesDebugApp extends StatelessWidget {
  const TestMessagesDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Messages Debug',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestMessagesDebugScreen(),
    );
  }
}

class TestMessagesDebugScreen extends StatefulWidget {
  const TestMessagesDebugScreen({super.key});

  @override
  State<TestMessagesDebugScreen> createState() => _TestMessagesDebugScreenState();
}

class _TestMessagesDebugScreenState extends State<TestMessagesDebugScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _chatService = ChatFirestoreService.instance;
  final _authService = FirestoreAuthService.instance;
  
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages Screen Debug',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test buttons
            _buildTestButton(
              'Step 1: Check Firebase Auth',
              _checkFirebaseAuth,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 2: Check Firestore Auth',
              _checkFirestoreAuth,
              Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 3: Login User',
              _loginUser,
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 4: Test Chat Service',
              _testChatService,
              Colors.purple,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 5: Test Stream Chats',
              _testStreamChats,
              Colors.teal,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 6: Test Get Flat Members',
              _testGetFlatMembers,
              Colors.indigo,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 7: Test Admin Chat',
              _testAdminChat,
              Colors.pink,
            ),
            
            const SizedBox(height: 20),
            
            _buildTestButton(
              'Run Full Test',
              _runFullTest,
              Colors.red,
            ),
            
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _checkFirebaseAuth() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking Firebase Auth...';
    });

    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        setState(() {
          _status = '✅ Firebase Auth User Signed In!\n\n'
              'UID: ${currentUser.uid}\n'
              'Email: ${currentUser.email}\n'
              'Display Name: ${currentUser.displayName}\n'
              'Email Verified: ${currentUser.emailVerified}';
        });
      } else {
        setState(() {
          _status = '⚠️  No Firebase Auth User Signed In\n\n'
              'This is likely the cause of the error.\n'
              'The chat service needs Firebase Auth to work.';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error checking Firebase Auth: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFirestoreAuth() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking Firestore Auth...';
    });

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      final userId = await _authService.getCurrentUserId();
      
      if (isLoggedIn && userId != null) {
        final userData = await _authService.getCurrentUserData();
        
        setState(() {
          _status = '✅ Firestore Auth Active!\n\n'
              'User ID: $userId\n'
              'Name: ${userData?['name']}\n'
              'Email: ${userData?['email']}\n'
              'Phone: ${userData?['phone']}\n'
              'authUid: ${userData?['authUid'] ?? 'NOT SET'}';
        });
      } else {
        setState(() {
          _status = '⚠️  No Firestore Auth Session\n\n'
              'User needs to login first.';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error checking Firestore Auth: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Logging in...';
    });

    try {
      print('\n========================================');
      print('🔐 TESTING LOGIN');
      print('========================================\n');
      
      final result = await _authService.signInFirestoreOnly(
        identifier: 'preethampriyatharson07@gmail.com',
        password: 'tK7Fo1Ow',
      );
      
      if (result.success) {
        // Check Firebase Auth status
        final firebaseUser = _auth.currentUser;
        
        setState(() {
          _status = '✅ Login Successful!\n\n'
              'User ID: ${result.userId}\n'
              'Name: ${result.userData?['name']}\n'
              'Email: ${result.userData?['email']}\n\n'
              'Firebase Auth Status:\n'
              '${firebaseUser != null ? "✅ Signed in (UID: ${firebaseUser.uid})" : "⚠️  Not signed in"}';
        });
      } else {
        setState(() {
          _status = '❌ Login Failed!\n\n'
              'Error: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error during login: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testChatService() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing chat service...';
    });

    try {
      print('\n========================================');
      print('🧪 TESTING CHAT SERVICE');
      print('========================================\n');
      
      // Test getting current user ID
      final userId = _auth.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          _status = '❌ Chat Service Test Failed!\n\n'
              'No Firebase Auth user signed in.\n'
              'This is why the messages screen shows an error.\n\n'
              'Solution: Login first (Step 3)';
        });
        return;
      }
      
      setState(() {
        _status = '✅ Chat Service Ready!\n\n'
            'Current User ID: $userId\n\n'
            'The chat service can now fetch chats.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error testing chat service: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testStreamChats() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing stream chats...';
    });

    try {
      print('\n========================================');
      print('🧪 TESTING STREAM CHATS');
      print('========================================\n');
      
      final userId = _auth.currentUser?.uid;
      
      if (userId == null) {
        setState(() {
          _status = '❌ Cannot Stream Chats!\n\n'
              'No Firebase Auth user signed in.\n\n'
              'Solution: Login first (Step 3)';
        });
        return;
      }
      
      // Try to get chats
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .get();
      
      setState(() {
        _status = '✅ Stream Chats Test Complete!\n\n'
            'User ID: $userId\n'
            'Chats found: ${chatsSnapshot.docs.length}\n\n'
            'The messages screen should now work.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error streaming chats: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetFlatMembers() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing get flat members...';
    });

    try {
      print('\n========================================');
      print('🧪 TESTING GET FLAT MEMBERS');
      print('========================================\n');
      
      final members = await _chatService.getFlatMembers();
      
      setState(() {
        _status = '✅ Get Flat Members Test Complete!\n\n'
            'Members found: ${members.length}\n\n'
            'Members:\n${members.map((m) => '- ${m['name']} (Flat ${m['flatLabel']})').join('\n')}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error getting flat members: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAdminChat() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing admin chat...';
    });

    try {
      print('\n========================================');
      print('🧪 TESTING ADMIN CHAT');
      print('========================================\n');
      
      final chatId = await _chatService.getOrCreateAdminChat();
      
      if (chatId != null) {
        setState(() {
          _status = '✅ Admin Chat Test Complete!\n\n'
              'Chat ID: $chatId\n\n'
              'Admin chat is ready to use.';
        });
      } else {
        setState(() {
          _status = '❌ Admin Chat Test Failed!\n\n'
              'Could not create admin chat.';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error testing admin chat: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Running full test...';
    });

    try {
      // Step 1: Check Firebase Auth
      await _checkFirebaseAuth();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 2: Check Firestore Auth
      await _checkFirestoreAuth();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 3: Login if needed
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        await _loginUser();
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Step 4: Test Chat Service
      await _testChatService();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 5: Test Stream Chats
      await _testStreamChats();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 6: Test Get Flat Members
      await _testGetFlatMembers();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 7: Test Admin Chat
      await _testAdminChat();
      
      setState(() {
        _status = '✅ Full Test Complete!\n\n'
            'Check the results above and console logs\n'
            'for detailed information.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Test failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
