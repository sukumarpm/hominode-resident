// Diagnostic script to identify billing data fetch issue
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const DiagnosticApp());
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Billing Diagnostic')),
        body: const DiagnosticScreen(),
      ),
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final _output = StringBuffer();
  bool _isRunning = false;

  void _log(String message) {
    setState(() {
      _output.writeln(message);
    });
    print(message);
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _output.clear();
    });

    try {
      _log('═══════════════════════════════════════');
      _log('🔍 BILLING DIAGNOSTIC START');
      _log('═══════════════════════════════════════\n');

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Step 1: Check current user
      _log('STEP 1: Check Current User');
      _log('─────────────────────────────────────');
      final user = auth.currentUser;
      
      if (user == null) {
        _log('❌ ERROR: No user logged in');
        _log('\nSOLUTION: Login first with:');
        _log('   Phone: 7010678124');
        _log('   Password: 121456');
        return;
      }
      
      _log('✅ User logged in');
      _log('   UID: ${user.uid}');
      _log('   Email: ${user.email ?? "N/A"}');
      _log('   Phone: ${user.phoneNumber ?? "N/A"}\n');

      // Step 2: Check user document
      _log('STEP 2: Check User Document');
      _log('─────────────────────────────────────');
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        _log('❌ ERROR: User document not found');
        _log('   Collection: users');
        _log('   Document ID: ${user.uid}');
        _log('\nSOLUTION: Create user document in Firebase Console');
        return;
      }
      
      final userData = userDoc.data()!;
      _log('✅ User document found');
      _log('   Fields: ${userData.keys.join(", ")}');
      _log('   flatId: ${userData['flatId'] ?? "MISSING"}');
      _log('   residentId: ${userData['residentId'] ?? "MISSING"}');
      _log('   name: ${userData['name'] ?? "MISSING"}\n');

      final flatId = userData['flatId'] as String?;
      final residentId = userData['residentId'] as String?;
      final residentName = userData['name'] as String?;

      if (flatId == null && residentId == null && residentName == null) {
        _log('❌ ERROR: No identifiers found');
        _log('   User has no flatId, residentId, or name');
        _log('\nSOLUTION: Add at least one identifier:');
        _log('   1. Go to Firebase Console');
        _log('   2. Firestore → users → ${user.uid}');
        _log('   3. Add field: flatId = "1202"');
        return;
      }

      // Step 3: Query all bills
      _log('STEP 3: Query All Bills');
      _log('─────────────────────────────────────');
      final allBills = await firestore.collection('bills').get();
      _log('✅ Total bills in collection: ${allBills.docs.length}\n');

      if (allBills.docs.isEmpty) {
        _log('❌ ERROR: No bills exist in Firestore');
        _log('\nSOLUTION: Create a bill in Firebase Console:');
        _log('   1. Go to Firestore → bills');
        _log('   2. Add document with:');
        _log('      flatId: "1202"');
        _log('      status: "pending"');
        _log('      amount: 6000');
        _log('      month: "February"');
        _log('      year: "2026"');
        return;
      }

      // Step 4: Check each bill for matches
      _log('STEP 4: Check Bills for Matches');
      _log('─────────────────────────────────────');
      
      int matchCount = 0;
      int pendingMatchCount = 0;
      
      for (var doc in allBills.docs) {
        final bill = doc.data();
        final billFlatId = bill['flatId'] as String?;
        final billResidentId = bill['residentId'] as String?;
        final billResidentName = bill['residentName'] as String?;
        final billStatus = bill['status'] as String?;
        
        bool matches = false;
        String matchReason = '';
        
        if (flatId != null && billFlatId == flatId) {
          matches = true;
          matchReason = 'flatId';
        } else if (residentId != null && billResidentId == residentId) {
          matches = true;
          matchReason = 'residentId';
        } else if (residentName != null && billResidentName == residentName) {
          matches = true;
          matchReason = 'residentName';
        }
        
        if (matches) {
          matchCount++;
          if (billStatus == 'pending') {
            pendingMatchCount++;
          }
          
          _log('✓ Bill ${doc.id}:');
          _log('   Matched by: $matchReason');
          _log('   flatId: $billFlatId');
          _log('   residentId: $billResidentId');
          _log('   residentName: $billResidentName');
          _log('   status: $billStatus');
          _log('   amount: ${bill['amount']}');
          _log('   month: ${bill['month']}');
          _log('');
        }
      }

      _log('─────────────────────────────────────');
      _log('SUMMARY:');
      _log('   Total bills: ${allBills.docs.length}');
      _log('   Matching bills: $matchCount');
      _log('   Pending matching bills: $pendingMatchCount\n');

      if (matchCount == 0) {
        _log('❌ ERROR: No matching bills found');
        _log('\nREASON: None of the bills match your identifiers');
        _log('\nYour identifiers:');
        _log('   flatId: $flatId');
        _log('   residentId: $residentId');
        _log('   name: $residentName');
        _log('\nSOLUTION: Update a bill to match:');
        _log('   1. Go to Firebase Console');
        _log('   2. Firestore → bills → (any bill)');
        _log('   3. Set flatId = "$flatId"');
        _log('   4. Set status = "pending"');
      } else if (pendingMatchCount == 0) {
        _log('⚠️  WARNING: Matching bills found but none are pending');
        _log('\nSOLUTION: Change a bill status to "pending":');
        _log('   1. Go to Firebase Console');
        _log('   2. Firestore → bills → (matching bill)');
        _log('   3. Set status = "pending"');
      } else {
        _log('✅ SUCCESS: Found $pendingMatchCount pending bill(s)');
        _log('\nThe app should display these bills.');
        _log('If not, check console logs for errors.');
      }

      _log('\n═══════════════════════════════════════');
      _log('🔍 DIAGNOSTIC COMPLETE');
      _log('═══════════════════════════════════════');

    } catch (e, stackTrace) {
      _log('\n❌ DIAGNOSTIC ERROR: $e');
      _log('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isRunning ? null : _runDiagnostic,
            child: Text(_isRunning ? 'Running...' : 'Run Diagnostic'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
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
