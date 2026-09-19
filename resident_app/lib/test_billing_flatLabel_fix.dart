// Test script to verify billing data fetch with flatLabel fallback
// Run: flutter run lib/test_billing_flatLabel_fix.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/bill_firestore_service.dart';
import 'src/services/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestBillingFlatLabelApp());
}

class TestBillingFlatLabelApp extends StatelessWidget {
  const TestBillingFlatLabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test Billing flatLabel Fix')),
        body: const TestBillingWidget(),
      ),
    );
  }
}

class TestBillingWidget extends StatefulWidget {
  const TestBillingWidget({super.key});

  @override
  State<TestBillingWidget> createState() => _TestBillingWidgetState();
}

class _TestBillingWidgetState extends State<TestBillingWidget> {
  final _billService = BillFirestoreService();
  final _userDataService = UserDataService();
  String _status = 'Starting test...';
  Map<String, dynamic>? _currentBill;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() => _status = '🔍 Step 1: Fetching user data...');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Step 1: Get user data
      final userData = await _userDataService.getCurrentUserData();
      
      if (userData == null) {
        setState(() => _status = '❌ FAILED: No user data found');
        return;
      }

      final flatId = userData['flatId'] as String?;
      final flatLabel = userData['flatLabel'] as String?;
      final residentId = userData['residentId'] as String?;
      final name = userData['name'] as String?;

      setState(() => _status = '''
✅ Step 1: User data fetched
   Name: $name
   flatId: ${flatId ?? 'NOT SET'}
   flatLabel: ${flatLabel ?? 'NOT SET'}
   residentId: ${residentId ?? 'NOT SET'}

🔍 Step 2: Fetching billing data...
''');
      await Future.delayed(const Duration(seconds: 1));

      // Step 2: Fetch current bill
      final bill = await _billService.getCurrentBill(forceRefresh: true);

      if (bill == null) {
        setState(() => _status = '''
✅ Step 1: User data fetched
   Name: $name
   flatId: ${flatId ?? 'NOT SET'}
   flatLabel: ${flatLabel ?? 'NOT SET'}
   residentId: ${residentId ?? 'NOT SET'}

❌ Step 2: FAILED - No pending bills found

DIAGNOSIS:
${flatId == null && flatLabel == null ? '⚠️  User has NO flatId or flatLabel field' : ''}
${flatId == null && flatLabel != null ? '✅ flatLabel exists ($flatLabel) - Fix applied!' : ''}
${flatId != null ? '✅ flatId exists ($flatId)' : ''}

Check Firebase Console:
1. Go to Firestore Database
2. Open "bills" collection
3. Verify bill exists with:
   - flatId: "${flatLabel ?? flatId ?? 'UNKNOWN'}"
   - status: "pending"
''');
        return;
      }

      // Success!
      setState(() {
        _currentBill = bill;
        _status = '''
✅ Step 1: User data fetched
   Name: $name
   flatId: ${flatId ?? 'NOT SET'}
   flatLabel: ${flatLabel ?? 'NOT SET'}
   residentId: ${residentId ?? 'NOT SET'}

✅ Step 2: Billing data fetched successfully!

📋 BILL DETAILS:
   Amount: ₹${bill['amount']}
   Month: ${bill['month']}
   Status: ${bill['status']}
   Flat: ${bill['flatId']}
   Resident: ${bill['residentName']}

🎉 SUCCESS! The flatLabel fallback fix is working!
''';
      });
    } catch (e, stackTrace) {
      setState(() => _status = '''
❌ ERROR: $e

Stack trace:
$stackTrace
''');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing flatLabel Fix Test',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This test verifies that billing service can fetch data using flatLabel as fallback when flatId is missing.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              _status,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          if (_currentBill != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A30), Color(0xFFFF4E17)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Bill',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${_currentBill!['amount']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Month: ${_currentBill!['month']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
