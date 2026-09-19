// lib/create_test_billing_data.dart
// Utility to create test billing data in Firestore

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTestBillingData extends StatefulWidget {
  const CreateTestBillingData({super.key});

  @override
  State<CreateTestBillingData> createState() => _CreateTestBillingDataState();
}

class _CreateTestBillingDataState extends State<CreateTestBillingData> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _log = '';
  bool _isLoading = false;
  String? _flatId;

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  Future<void> _createTestData() async {
    setState(() {
      _log = '';
      _isLoading = true;
    });

    try {
      _addLog('=== CREATING TEST BILLING DATA ===\n');

      // Step 1: Get current user
      final user = _auth.currentUser;
      if (user == null) {
        _addLog('❌ ERROR: No user logged in');
        setState(() => _isLoading = false);
        return;
      }
      _addLog('✅ Current User: ${user.uid}');
      _addLog('   Email: ${user.email}\n');

      // Step 2: Check if flat exists
      _addLog('🔍 Checking for existing flat...');
      final existingFlat = await _firestore
          .collection('flats')
          .where('residentIds', arrayContains: user.uid)
          .get();

      if (existingFlat.docs.isNotEmpty) {
        _flatId = existingFlat.docs.first.id;
        _addLog('✅ Flat already exists: $_flatId\n');
      } else {
        // Create a new flat
        _addLog('📝 Creating new flat...');
        final flatRef = await _firestore.collection('flats').add({
          'flatNumber': 'A-101',
          'buildingId': 'building_001',
          'residentIds': [user.uid],
          'floor': 1,
          'bhk': 2,
          'area': 1000,
          'status': 'occupied',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _flatId = flatRef.id;
        _addLog('✅ Flat created: $_flatId');
        _addLog('   Flat Number: A-101\n');
      }

      // Step 3: Create pending bill
      _addLog('📝 Creating pending bill...');
      final pendingBillRef = await _firestore.collection('bills').add({
        'flatId': _flatId,
        'amount': 5000,
        'status': 'pending',
        'month': 'February 2024',
        'dueDate': Timestamp.fromDate(DateTime(2024, 2, 28)),
        'maintenanceCharge': 3000,
        'waterCharge': 500,
        'parkingCharge': 1000,
        'serviceCharge': 500,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _addLog('✅ Pending bill created: ${pendingBillRef.id}');
      _addLog('   Amount: ₹5000');
      _addLog('   Status: pending');
      _addLog('   Month: February 2024\n');

      // Step 4: Create paid bill (for history)
      _addLog('📝 Creating paid bill...');
      final paidBillRef = await _firestore.collection('bills').add({
        'flatId': _flatId,
        'amount': 4800,
        'status': 'paid',
        'month': 'January 2024',
        'dueDate': Timestamp.fromDate(DateTime(2024, 1, 31)),
        'paidAt': Timestamp.fromDate(DateTime(2024, 1, 25, 10, 30)),
        'paymentMethod': 'UPI',
        'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'maintenanceCharge': 3000,
        'waterCharge': 500,
        'parkingCharge': 800,
        'serviceCharge': 500,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _addLog('✅ Paid bill created: ${paidBillRef.id}');
      _addLog('   Amount: ₹4800');
      _addLog('   Status: paid');
      _addLog('   Month: January 2024\n');

      // Step 5: Create another paid bill
      _addLog('📝 Creating another paid bill...');
      final paidBillRef2 = await _firestore.collection('bills').add({
        'flatId': _flatId,
        'amount': 4500,
        'status': 'paid',
        'month': 'December 2023',
        'dueDate': Timestamp.fromDate(DateTime(2023, 12, 31)),
        'paidAt': Timestamp.fromDate(DateTime(2023, 12, 28, 14, 15)),
        'paymentMethod': 'Card',
        'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch - 1000}',
        'maintenanceCharge': 3000,
        'waterCharge': 500,
        'parkingCharge': 500,
        'serviceCharge': 500,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _addLog('✅ Paid bill created: ${paidBillRef2.id}');
      _addLog('   Amount: ₹4500');
      _addLog('   Status: paid');
      _addLog('   Month: December 2023\n');

      _addLog('=== TEST DATA CREATED SUCCESSFULLY ===');
      _addLog('\n📊 Summary:');
      _addLog('   Flat ID: $_flatId');
      _addLog('   Pending Bills: 1');
      _addLog('   Paid Bills: 2');
      _addLog('\n✅ Go back to Maintenance & Billing screen to see the data!');

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: const Text(
              'Test billing data has been created successfully.\n\n'
              'Go back to see the bills in the Maintenance & Billing screen.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Go back with success
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      _addLog('\n❌ ERROR: $e');
      _addLog('Stack trace: $stackTrace');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Test Billing Data'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will create test billing data in Firestore:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text('• 1 Flat (if not exists)'),
                const Text('• 1 Pending Bill (₹5000)'),
                const Text('• 2 Paid Bills (₹4800, ₹4500)'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createTestData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Test Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log.isEmpty ? 'Press button to create test data...' : _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
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
