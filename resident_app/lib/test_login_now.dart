// Quick Login Test
// Run: flutter run lib/test_login_now.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/firebase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LoginTestApp());
}

class LoginTestApp extends StatelessWidget {
  const LoginTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Test',
      home: const LoginTestScreen(),
    );
  }
}

class LoginTestScreen extends StatefulWidget {
  const LoginTestScreen({super.key});

  @override
  State<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends State<LoginTestScreen> {
  final _authService = FirebaseAuthService();
  String _result = 'Ready to test...';
  bool _isLoading = false;

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing login...';
    });

    // Test with phone number from your screenshot
    final result = await _authService.signInWithEmail(
      email: '7010678124',  // Phone number
      password: '121456',    // Password from screenshot
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        _result = '✅ SUCCESS!\n\n'
            'User: ${result.user?.email}\n'
            'UID: ${result.user?.uid}\n\n'
            'You can now login with:\n'
            'Phone: 7010678124\n'
            'Password: 121456';
      } else {
        _result = '❌ FAILED\n\n'
            'Error: ${result.message}\n'
            'Code: ${result.errorCode ?? "none"}';
      }
    });
  }

  Future<void> _testEmailLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing email login...';
    });

    // Test with email directly
    final result = await _authService.signInWithEmail(
      email: 'preethampriyadharshan07@gmail.com',
      password: '121456',
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        _result = '✅ EMAIL LOGIN SUCCESS!\n\n'
            'User: ${result.user?.email}\n'
            'UID: ${result.user?.uid}';
      } else {
        _result = '❌ EMAIL LOGIN FAILED\n\n'
            'Error: ${result.message}\n'
            'Code: ${result.errorCode ?? "none"}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Login Credentials',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Phone: 7010678124\n'
              'Email: preethampriyadharshan07@gmail.com\n'
              'Password: 121456',
              style: TextStyle(fontSize: 16),
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
