// Quick script to diagnose and fix login issue
// Run: flutter run -t lib/fix_login_issue.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const LoginFixApp());
}

class LoginFixApp extends StatelessWidget {
  const LoginFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Login Issue Fix')),
        body: const LoginFixScreen(),
      ),
    );
  }
}

class LoginFixScreen extends StatefulWidget {
  const LoginFixScreen({super.key});

  @override
  State<LoginFixScreen> createState() => _LoginFixScreenState();
}

class _LoginFixScreenState extends State<LoginFixScreen> {
  final _emailController = TextEditingController(
    text: 'preethampriyatharson07@gmail.com',
  );
  final _passwordController = TextEditingController(
    text: '*DvgIDLEy*',
  );
  
  String _log = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  Future<void> _diagnoseAndFix() async {
    setState(() {
      _log = '';
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      _addLog('🔍 Starting diagnosis...');
      _addLog('Email: $email');
      _addLog('');

      // Step 1: Check if user exists in Firestore
      _addLog('📋 Step 1: Checking Firestore users collection...');
      final firestoreQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (firestoreQuery.docs.isEmpty) {
        _addLog('❌ User not found in Firestore!');
        _addLog('Please create user in Firestore first.');
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = firestoreQuery.docs.first;
      final userData = userDoc.data();
      _addLog('✅ User found in Firestore');
      _addLog('   Name: ${userData['name']}');
      _addLog('   ResidentId: ${userData['residentId']}');
      _addLog('   FlatId: ${userData['flatId']}');
      _addLog('   Password in Firestore: ${userData['password']}');
      _addLog('');

      // Step 2: Check if user exists in Firebase Auth
      _addLog('🔐 Step 2: Checking Firebase Authentication...');
      
      try {
        // Try to sign in
        _addLog('Attempting to sign in...');
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        _addLog('✅ User exists in Firebase Auth and password is correct!');
        _addLog('   UID: ${userCredential.user?.uid}');
        _addLog('');
        _addLog('🎉 Login should work now!');
        
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          _addLog('⚠️  User not found in Firebase Auth');
          _addLog('');
          
          // Step 3: Create user in Firebase Auth
          _addLog('🔧 Step 3: Creating user in Firebase Auth...');
          try {
            final newUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            _addLog('✅ User created in Firebase Auth!');
            _addLog('   UID: ${newUserCredential.user?.uid}');
            
            // Update display name
            await newUserCredential.user?.updateDisplayName(userData['name']);
            _addLog('✅ Display name updated');
            
            _addLog('');
            _addLog('🎉 FIX COMPLETE! Login should work now!');
            _addLog('');
            _addLog('Try logging in with:');
            _addLog('Email: $email');
            _addLog('Password: $password');
            
          } catch (createError) {
            _addLog('❌ Failed to create user: $createError');
          }
          
        } else if (e.code == 'wrong-password') {
          _addLog('❌ User exists but password is wrong!');
          _addLog('');
          _addLog('🔧 Step 3: Resetting password in Firebase Auth...');
          
          // Delete and recreate user
          try {
            // Sign in with any password to get user object
            _addLog('Attempting to delete old user...');
            
            // Send password reset email instead
            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
            _addLog('✅ Password reset email sent to $email');
            _addLog('');
            _addLog('OR manually delete user in Firebase Console and run this again');
            
          } catch (resetError) {
            _addLog('❌ Failed to reset: $resetError');
            _addLog('');
            _addLog('MANUAL FIX REQUIRED:');
            _addLog('1. Go to Firebase Console → Authentication');
            _addLog('2. Delete user: $email');
            _addLog('3. Run this script again');
          }
          
        } else {
          _addLog('❌ Firebase Auth error: ${e.code}');
          _addLog('   Message: ${e.message}');
        }
      }

    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Login Issue Diagnostic Tool',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _diagnoseAndFix,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Diagnose & Fix Login Issue'),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log.isEmpty ? 'Tap button to start diagnosis...' : _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
