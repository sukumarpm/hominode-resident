// lib/test_firestore_connection.dart
// Simple test to verify Firestore connection

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestFirestoreConnection extends StatefulWidget {
  const TestFirestoreConnection({super.key});

  @override
  State<TestFirestoreConnection> createState() => _TestFirestoreConnectionState();
}

class _TestFirestoreConnectionState extends State<TestFirestoreConnection> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _status = 'Ready to test';
  bool _isLoading = false;

  // Test 1: Simple write and read
  Future<void> _testSimpleWrite() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing simple write...';
    });

    try {
      print('🧪 Test 1: Simple Write/Read');
      
      // Write test document
      await _firestore.collection('test').doc('connection_test').set({
        'message': 'Hello Firestore!',
        'timestamp': FieldValue.serverTimestamp(),
        'testNumber': 123,
      });
      
      print('✅ Write successful');
      
      // Read test document
      final doc = await _firestore.collection('test').doc('connection_test').get();
      
      if (doc.exists) {
        print('✅ Read successful');
        print('📄 Data: ${doc.data()}');
        
        setState(() {
          _status = '✅ SUCCESS!\n\nFirestore is working!\n\nData: ${doc.data()}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '❌ Document not found after write';
          _isLoading = false;
        });
      }
      
      // Clean up
      await _firestore.collection('test').doc('connection_test').delete();
      print('🧹 Test document deleted');
      
    } catch (e) {
      print('❌ Test failed: $e');
      setState(() {
        _status = '❌ FAILED\n\nError: $e\n\nCheck security rules!';
        _isLoading = false;
      });
    }
  }

  // Test 2: Create user with auth and save to Firestore
  Future<void> _testFullRegistration() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing full registration flow...';
    });

    try {
      print('🧪 Test 2: Full Registration Flow');
      
      final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'Test123!';
      
      print('📧 Creating auth user: $testEmail');
      
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }
      
      print('✅ Auth user created: ${user.uid}');
      
      // Save to Firestore
      print('💾 Saving to Firestore...');
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': 'Test User',
        'email': testEmail,
        'phone': '1234567890',
        'role': 'resident',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      print('✅ Firestore write successful');
      
      // Verify data was saved
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        print('✅ Data verified in Firestore');
        print('📄 User data: ${doc.data()}');
        
        setState(() {
          _status = '✅ FULL SUCCESS!\n\n'
              'Auth user created: ${user.uid}\n\n'
              'Data saved to Firestore!\n\n'
              'Check Firebase Console → Firestore → users collection';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '⚠️ Auth succeeded but Firestore write failed';
          _isLoading = false;
        });
      }
      
      // Clean up - delete test user
      await user.delete();
      await _firestore.collection('users').doc(user.uid).delete();
      print('🧹 Test user cleaned up');
      
    } catch (e) {
      print('❌ Test failed: $e');
      setState(() {
        _status = '❌ FAILED\n\nError: $e\n\n'
            'Possible causes:\n'
            '1. Security rules blocking writes\n'
            '2. Firestore not enabled\n'
            '3. Network issue';
        _isLoading = false;
      });
    }
  }

  // Test 3: Check current security rules
  Future<void> _checkSecurityRules() async {
    setState(() {
      _status = 'Checking security rules...\n\n'
          'Go to Firebase Console:\n'
          '1. Firestore Database\n'
          '2. Rules tab\n'
          '3. Check if rules allow writes\n\n'
          'For testing, use:\n'
          'allow read, write: if true;';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firestore Connection'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSimpleWrite,
              icon: const Icon(Icons.science),
              label: const Text('Test 1: Simple Write/Read'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFullRegistration,
              icon: const Icon(Icons.person_add),
              label: const Text('Test 2: Full Registration Flow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _checkSecurityRules,
              icon: const Icon(Icons.security),
              label: const Text('Check Security Rules'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
