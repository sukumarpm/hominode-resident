// Test Firebase Auth Auto-Creation
// Run this to test if Firebase Auth users are created automatically on login

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'src/services/firestore_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TestFirebaseAuthCreationApp());
}

class TestFirebaseAuthCreationApp extends StatelessWidget {
  const TestFirebaseAuthCreationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Firebase Auth Creation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestFirebaseAuthCreationScreen(),
    );
  }
}

class TestFirebaseAuthCreationScreen extends StatefulWidget {
  const TestFirebaseAuthCreationScreen({super.key});

  @override
  State<TestFirebaseAuthCreationScreen> createState() => _TestFirebaseAuthCreationScreenState();
}

class _TestFirebaseAuthCreationScreenState extends State<TestFirebaseAuthCreationScreen> {
  final _authService = FirestoreAuthService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  String _status = 'Ready to test';
  bool _isLoading = false;
  
  // Test credentials
  final String testEmail = 'preethampriyatharson07@gmail.com';
  final String testPhone = '7010678124';
  final String testPassword = 'tK7Fo1Ow';
  final String testUserId = 'ZsjxqVHSv7OQELHCFee1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Auth Creation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Auth Auto-Creation Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Test credentials
            _buildInfoCard(
              'Test Credentials',
              [
                'Email: $testEmail',
                'Phone: $testPhone',
                'Password: $testPassword',
                'User ID: $testUserId',
              ],
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
              'Step 1: Check Firestore User',
              _checkFirestoreUser,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 2: Check Firebase Auth User',
              _checkFirebaseAuthUser,
              Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 3: Test Login (Email)',
              () => _testLogin(testEmail),
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 4: Test Login (Phone)',
              () => _testLogin(testPhone),
              Colors.teal,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 5: Verify Firebase Auth Created',
              _verifyFirebaseAuthCreated,
              Colors.purple,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              'Step 6: Check authUid in Firestore',
              _checkAuthUidInFirestore,
              Colors.indigo,
            ),
            
            const SizedBox(height: 20),
            
            // Full test
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

  Widget _buildInfoCard(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item),
          )),
        ],
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

  Future<void> _checkFirestoreUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking Firestore user...';
    });

    try {
      final doc = await _firestore.collection('users').doc(testUserId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _status = '✅ Firestore User Found!\n\n'
              'Name: ${data['name']}\n'
              'Email: ${data['email']}\n'
              'Phone: ${data['phone']}\n'
              'Password: ${data['password']}\n'
              'authUid: ${data['authUid'] ?? 'NOT SET'}\n'
              'Status: ${data['status']}';
        });
      } else {
        setState(() {
          _status = '❌ Firestore user not found!';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFirebaseAuthUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking Firebase Auth user...';
    });

    try {
      final methods = await _auth.fetchSignInMethodsForEmail(testEmail);
      
      if (methods.isNotEmpty) {
        setState(() {
          _status = '✅ Firebase Auth User Exists!\n\n'
              'Email: $testEmail\n'
              'Sign-in methods: ${methods.join(', ')}\n\n'
              'Note: User exists in Firebase Auth';
        });
      } else {
        setState(() {
          _status = '⚠️  Firebase Auth User NOT Found\n\n'
              'Email: $testEmail\n'
              'This user needs to be created.\n\n'
              'Will be created automatically on login.';
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

  Future<void> _testLogin(String identifier) async {
    setState(() {
      _isLoading = true;
      _status = 'Testing login with $identifier...';
    });

    try {
      print('\n========================================');
      print('🧪 TESTING LOGIN');
      print('========================================');
      print('Identifier: $identifier');
      print('Password: $testPassword');
      print('========================================\n');
      
      final result = await _authService.signInFirestoreOnly(
        identifier: identifier,
        password: testPassword,
      );
      
      if (result.success) {
        setState(() {
          _status = '✅ Login Successful!\n\n'
              'User ID: ${result.userId}\n'
              'Name: ${result.userData?['name']}\n'
              'Email: ${result.userData?['email']}\n\n'
              'Check console logs for Firebase Auth creation details.';
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

  Future<void> _verifyFirebaseAuthCreated() async {
    setState(() {
      _isLoading = true;
      _status = 'Verifying Firebase Auth user creation...';
    });

    try {
      // Check if currently signed in
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        setState(() {
          _status = '✅ Firebase Auth User Signed In!\n\n'
              'UID: ${currentUser.uid}\n'
              'Email: ${currentUser.email}\n'
              'Display Name: ${currentUser.displayName}\n'
              'Email Verified: ${currentUser.emailVerified}\n\n'
              'Firebase Auth account is active!';
        });
      } else {
        // Check if user exists
        final methods = await _auth.fetchSignInMethodsForEmail(testEmail);
        
        if (methods.isNotEmpty) {
          setState(() {
            _status = '⚠️  Firebase Auth User Exists but Not Signed In\n\n'
                'Email: $testEmail\n'
                'Sign-in methods: ${methods.join(', ')}\n\n'
                'User was created but session ended.';
          });
        } else {
          setState(() {
            _status = '❌ Firebase Auth User NOT Created\n\n'
                'The automatic creation may have failed.\n'
                'Check console logs for errors.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error verifying Firebase Auth: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAuthUidInFirestore() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking authUid in Firestore...';
    });

    try {
      final doc = await _firestore.collection('users').doc(testUserId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final authUid = data['authUid'] as String?;
        
        if (authUid != null && authUid.isNotEmpty) {
          setState(() {
            _status = '✅ authUid Found in Firestore!\n\n'
                'User ID: $testUserId\n'
                'authUid: $authUid\n\n'
                'Firebase Auth and Firestore are linked!';
          });
        } else {
          setState(() {
            _status = '⚠️  authUid NOT Set in Firestore\n\n'
                'User ID: $testUserId\n'
                'authUid: NOT SET\n\n'
                'Firebase Auth user may not have been created,\n'
                'or the authUid was not stored.';
          });
        }
      } else {
        setState(() {
          _status = '❌ Firestore user not found!';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
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
      // Step 1: Check Firestore
      await _checkFirestoreUser();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 2: Check Firebase Auth before login
      await _checkFirebaseAuthUser();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 3: Test login
      await _testLogin(testEmail);
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 4: Verify Firebase Auth created
      await _verifyFirebaseAuthCreated();
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 5: Check authUid
      await _checkAuthUidInFirestore();
      
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
