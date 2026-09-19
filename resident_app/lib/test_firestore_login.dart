// Test Firestore Login
// Run: flutter run lib/test_firestore_login.dart -d chrome

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/firestore_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FirestoreLoginTestApp());
}

class FirestoreLoginTestApp extends StatelessWidget {
  const FirestoreLoginTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Login Test',
      home: const FirestoreLoginTestScreen(),
    );
  }
}

class FirestoreLoginTestScreen extends StatefulWidget {
  const FirestoreLoginTestScreen({super.key});

  @override
  State<FirestoreLoginTestScreen> createState() => _FirestoreLoginTestScreenState();
}

class _FirestoreLoginTestScreenState extends State<FirestoreLoginTestScreen> {
  final _authService = FirestoreAuthService();
  final _phoneController = TextEditingController(text: '7010678124');
  final _passwordController = TextEditingController(text: '121456');
  String _result = 'Ready to test...';
  bool _isLoading = false;

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing login...';
    });

    final phone = _phoneController.text;
    final password = _passwordController.text;

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('TESTING FIRESTORE LOGIN');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Phone: $phone');
    print('Password: $password\n');

    final result = await _authService.signIn(
      identifier: phone,
      password: password,
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        final userData = result.userData!;
        _result = '✅ LOGIN SUCCESSFUL!\n\n'
            'User ID: ${result.userId}\n'
            'Name: ${userData['name']}\n'
            'Email: ${userData['email']}\n'
            'Phone: ${userData['phone']}\n'
            'Flat: ${userData['flatLabel']}\n'
            'Role: ${userData['role']}\n\n'
            'You can now login with:\n'
            'Phone: $phone\n'
            'Password: $password';
      } else {
        _result = '❌ LOGIN FAILED\n\n'
            'Error: ${result.message}\n\n'
            'Please check:\n'
            '1. Phone number exists in Firestore\n'
            '2. Password field exists in user document\n'
            '3. Password matches exactly';
      }
    });

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('RESULT: ${result.success ? "SUCCESS" : "FAILED"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  Future<void> _testEmailLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing email login...';
    });

    final result = await _authService.signIn(
      identifier: 'preethampriyadharshan07@gmail.com',
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        final userData = result.userData!;
        _result = '✅ EMAIL LOGIN SUCCESSFUL!\n\n'
            'User ID: ${result.userId}\n'
            'Name: ${userData['name']}\n'
            'Email: ${userData['email']}\n'
            'Phone: ${userData['phone']}';
      } else {
        _result = '❌ EMAIL LOGIN FAILED\n\n'
            'Error: ${result.message}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Login Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Firestore Authentication',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Test Phone Login',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testEmailLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Test Email Login',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
