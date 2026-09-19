// lib/diagnose_billing_flow.dart
// Diagnostic tool to verify complete billing data flow

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'src/services/firestore_auth_service.dart';
import 'src/services/user_data_service.dart';
import 'src/services/bill_firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DiagnoseBillingFlowApp());
}

class DiagnoseBillingFlowApp extends StatelessWidget {
  const DiagnoseBillingFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billing Flow Diagnostic',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DiagnosticScreen(),
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final _authService = FirestoreAuthService();
  final _userDataService = UserDataService();
  final _billService = BillFirestoreService();
  
  final _emailController = TextEditingController(text: 'preethampriyatharson07@gmail.com');
  final _passwordController = TextEditingController(text: 'DvgIDLEy');
  
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print(message);
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _logs.clear();
      _isRunning = true;
    });

    try {
      _addLog('🚀 Starting Billing Flow Diagnostic...');
      _addLog('');
      
      // STEP 1: Check SharedPreferences
      _addLog('📋 STEP 1: Checking SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final storedUserId = prefs.getString('user_id');
      final storedEmail = prefs.getString('user_email');
      
      _addLog('   is_logged_in: $isLoggedIn');
      _addLog('   user_id: $storedUserId');
      _addLog('   user_email: $storedEmail');
      _addLog('');
      
      // STEP 2: Login with Firestore-only
      _addLog('📋 STEP 2: Login with Firestore-only');
      _addLog('   Email: ${_emailController.text}');
      _addLog('   Password: ${_passwordController.text}');
      
      final authResult = await _authService.signInFirestoreOnly(
        identifier: _emailController.text,
        password: _passwordController.text,
      );
      
      if (!authResult.success) {
        _addLog('   ❌ Login failed: ${authResult.message}');
        setState(() => _isRunning = false);
        return;
      }
      
      _addLog('   ✅ Login successful');
      _addLog('   User ID: ${authResult.userId}');
      _addLog('   User Name: ${authResult.userData?['name']}');
      _addLog('');
      
      // STEP 3: Verify SharedPreferences after login
      _addLog('📋 STEP 3: Verify SharedPreferences after login');
      await Future.delayed(const Duration(milliseconds: 500));
      final prefsAfter = await SharedPreferences.getInstance();
      final isLoggedInAfter = prefsAfter.getBool('is_logged_in') ?? false;
      final storedUserIdAfter = prefsAfter.getString('user_id');
      
      _addLog('   is_logged_in: $isLoggedInAfter');
      _addLog('   user_id: $storedUserIdAfter');
      
      if (!isLoggedInAfter || storedUserIdAfter == null) {
        _addLog('   ❌ Login state not saved properly!');
        setState(() => _isRunning = false);
        return;
      }
      _addLog('   ✅ Login state saved correctly');
      _addLog('');
      
      // STEP 4: Get user data via UserDataService
      _addLog('📋 STEP 4: Get user data via UserDataService');
      final userData = await _userDataService.getCurrentUserData(forceRefresh: true);
      
      if (userData == null) {
        _addLog('   ❌ UserDataService returned null');
        setState(() => _isRunning = false);
        return;
      }
      
      _addLog('   ✅ User data retrieved');
      _addLog('   Name: ${userData['name']}');
      _addLog('   Email: ${userData['email']}');
      _addLog('   Phone: ${userData['phone']}');
      _addLog('   flatId: ${userData['flatId']}');
      _addLog('   flatLabel: ${userData['flatLabel']}');
      _addLog('   residentId: ${userData['residentId']}');
      _addLog('');
      
      // STEP 5: Extract identifiers from user data
      _addLog('📋 STEP 5: Extract identifiers for billing query');
      final residentId = userData['residentId'] as String?;
      final flatId = userData['flatId'] as String? ?? userData['flatLabel'] as String?;
      
      _addLog('   flatId: $flatId');
      _addLog('   residentId: $residentId');
      _addLog('');
      
      // STEP 6: Query Firestore bills collection directly
      _addLog('📋 STEP 6: Query Firestore bills collection directly');
      
      if (residentId != null && residentId.isNotEmpty) {
        _addLog('   Querying by residentId: $residentId');
        final querySnapshot = await FirebaseFirestore.instance
            .collection('bills')
            .where('residentId', isEqualTo: residentId)
            .get();
        
        _addLog('   Found ${querySnapshot.docs.length} bills by residentId');
        
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          _addLog('   - Bill ID: ${doc.id}');
          _addLog('     Amount: ${data['amount']}');
          _addLog('     Status: ${data['status']}');
          _addLog('     Month: ${data['month']}');
        }
      } else if (flatId != null && flatId.isNotEmpty) {
        _addLog('   Querying by flatId: $flatId');
        final querySnapshot = await FirebaseFirestore.instance
            .collection('bills')
            .where('flatId', isEqualTo: flatId)
            .get();
        
        _addLog('   Found ${querySnapshot.docs.length} bills by flatId');
        
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          _addLog('   - Bill ID: ${doc.id}');
          _addLog('     Amount: ${data['amount']}');
          _addLog('     Status: ${data['status']}');
          _addLog('     Month: ${data['month']}');
        }
      } else {
        _addLog('   ❌ No valid identifier for query');
      }
      _addLog('');
      
      // STEP 7: Use BillService.streamBills()
      _addLog('📋 STEP 7: Test BillService.streamBills()');
      _addLog('   Listening to stream for 3 seconds...');
      
      final streamSubscription = _billService.streamBills().listen((bills) {
        _addLog('   📡 Stream update: ${bills.length} bills');
        for (var bill in bills) {
          _addLog('   - ${bill['month']}: ₹${bill['amount']} (${bill['status']})');
        }
      });
      
      await Future.delayed(const Duration(seconds: 3));
      await streamSubscription.cancel();
      _addLog('');
      
      // STEP 8: Check all bills in Firestore (no filter)
      _addLog('📋 STEP 8: Check all bills in Firestore (no filter)');
      final allBillsSnapshot = await FirebaseFirestore.instance
          .collection('bills')
          .get();
      
      _addLog('   Total bills in collection: ${allBillsSnapshot.docs.length}');
      
      for (var doc in allBillsSnapshot.docs) {
        final data = doc.data();
        _addLog('   - Bill ID: ${doc.id}');
        _addLog('     flatId: ${data['flatId']}');
        _addLog('     residentId: ${data['residentId']}');
        _addLog('     amount: ${data['amount']}');
        _addLog('     status: ${data['status']}');
      }
      _addLog('');
      
      _addLog('✅ Diagnostic complete!');
      
    } catch (e, stackTrace) {
      _addLog('❌ Error: $e');
      _addLog('Stack trace: $stackTrace');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Flow Diagnostic'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Password input
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            
            const SizedBox(height: 16),
            
            // Run button
            ElevatedButton(
              onPressed: _isRunning ? null : _runDiagnostic,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                _isRunning ? 'Running...' : 'Run Diagnostic',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
