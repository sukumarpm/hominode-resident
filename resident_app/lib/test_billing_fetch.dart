// lib/test_billing_fetch.dart
// Test utility to debug billing data fetch

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestBillingFetch extends StatefulWidget {
  const TestBillingFetch({super.key});

  @override
  State<TestBillingFetch> createState() => _TestBillingFetchState();
}

class _TestBillingFetchState extends State<TestBillingFetch> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  String _log = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  Future<void> _testBillingFlow() async {
    setState(() {
      _log = '';
      _isLoading = true;
    });

    try {
      _addLog('=== BILLING FLOW TEST ===\n');

      // Step 1: Get current user
      final user = _auth.currentUser;
      if (user == null) {
        _addLog('❌ ERROR: No user logged in');
        setState(() => _isLoading = false);
        return;
      }
      _addLog('✅ Step 1: Current User');
      _addLog('   User ID: ${user.uid}');
      _addLog('   Email: ${user.email}\n');

      // Step 2: Check user document
      _addLog('🔍 Step 2: Checking user document...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _addLog('✅ User document exists');
        _addLog('   Data: ${userDoc.data()}\n');
      } else {
        _addLog('⚠️ User document does NOT exist\n');
      }

      // Step 3: Find flat assignment
      _addLog('🔍 Step 3: Finding flat assignment...');
      _addLog('   Query: flats WHERE residentIds CONTAINS ${user.uid}');
      
      final flatSnapshot = await _firestore
          .collection('flats')
          .where('residentIds', arrayContains: user.uid)
          .get();

      if (flatSnapshot.docs.isEmpty) {
        _addLog('❌ ERROR: No flat found for user');
        _addLog('   User is not assigned to any flat\n');
        
        // Check all flats
        _addLog('🔍 Checking all flats in database...');
        final allFlats = await _firestore.collection('flats').get();
        _addLog('   Total flats in database: ${allFlats.docs.length}');
        
        if (allFlats.docs.isNotEmpty) {
          _addLog('\n📋 Available flats:');
          for (var doc in allFlats.docs) {
            final data = doc.data();
            _addLog('   - Flat ID: ${doc.id}');
            _addLog('     Flat Number: ${data['flatNumber']}');
            _addLog('     Resident IDs: ${data['residentIds']}');
          }
        }
        
        setState(() => _isLoading = false);
        return;
      }

      final flatDoc = flatSnapshot.docs.first;
      final flatId = flatDoc.id;
      final flatData = flatDoc.data();
      
      _addLog('✅ Flat found!');
      _addLog('   Flat ID: $flatId');
      _addLog('   Flat Number: ${flatData['flatNumber']}');
      _addLog('   Building ID: ${flatData['buildingId']}');
      _addLog('   Resident IDs: ${flatData['residentIds']}\n');

      // Step 4: Query bills for this flat
      _addLog('🔍 Step 4: Querying bills...');
      _addLog('   Query: bills WHERE flatId == $flatId');
      
      final billsSnapshot = await _firestore
          .collection('bills')
          .where('flatId', isEqualTo: flatId)
          .get();

      _addLog('   Found ${billsSnapshot.docs.length} bills\n');

      if (billsSnapshot.docs.isEmpty) {
        _addLog('⚠️ No bills found for this flat\n');
        
        // Check all bills
        _addLog('🔍 Checking all bills in database...');
        final allBills = await _firestore.collection('bills').get();
        _addLog('   Total bills in database: ${allBills.docs.length}');
        
        if (allBills.docs.isNotEmpty) {
          _addLog('\n📋 Available bills:');
          for (var doc in allBills.docs) {
            final data = doc.data();
            _addLog('   - Bill ID: ${doc.id}');
            _addLog('     Flat ID: ${data['flatId']}');
            _addLog('     Amount: ${data['amount']}');
            _addLog('     Status: ${data['status']}');
            _addLog('     Month: ${data['month']}');
          }
        }
      } else {
        _addLog('✅ Bills found!\n');
        
        // Display all bills
        for (var doc in billsSnapshot.docs) {
          final data = doc.data();
          _addLog('📄 Bill ID: ${doc.id}');
          _addLog('   Flat ID: ${data['flatId']}');
          _addLog('   Amount: ₹${data['amount']}');
          _addLog('   Status: ${data['status']}');
          _addLog('   Month: ${data['month']}');
          _addLog('   Due Date: ${data['dueDate']}');
          
          if (data['maintenanceCharge'] != null) {
            _addLog('   Maintenance: ₹${data['maintenanceCharge']}');
          }
          if (data['waterCharge'] != null) {
            _addLog('   Water: ₹${data['waterCharge']}');
          }
          if (data['parkingCharge'] != null) {
            _addLog('   Parking: ₹${data['parkingCharge']}');
          }
          if (data['serviceCharge'] != null) {
            _addLog('   Service: ₹${data['serviceCharge']}');
          }
          _addLog('');
        }

        // Step 5: Filter pending bills
        final pendingBills = billsSnapshot.docs
            .where((doc) => doc.data()['status'] == 'pending')
            .toList();
        
        _addLog('📊 Summary:');
        _addLog('   Total bills: ${billsSnapshot.docs.length}');
        _addLog('   Pending bills: ${pendingBills.length}');
        _addLog('   Paid bills: ${billsSnapshot.docs.length - pendingBills.length}');
      }

      _addLog('\n=== TEST COMPLETE ===');
      
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
        title: const Text('Test Billing Fetch'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testBillingFlow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
                      'Run Billing Flow Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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
                  _log.isEmpty ? 'Press button to run test...' : _log,
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
