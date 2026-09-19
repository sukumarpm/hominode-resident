// lib/diagnose_flat_members.dart
// Diagnostic script to check flat members fetching

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DiagnoseFlatMembersApp());
}

class DiagnoseFlatMembersApp extends StatelessWidget {
  const DiagnoseFlatMembersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnose Flat Members',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DiagnoseFlatMembersScreen(),
    );
  }
}

class DiagnoseFlatMembersScreen extends StatefulWidget {
  const DiagnoseFlatMembersScreen({super.key});

  @override
  State<DiagnoseFlatMembersScreen> createState() => _DiagnoseFlatMembersScreenState();
}

class _DiagnoseFlatMembersScreenState extends State<DiagnoseFlatMembersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _output = 'Tap "Run Diagnosis" to start';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnose Flat Members'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runDiagnosis,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Run Diagnosis', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _isLoading = true;
      _output = 'Running diagnosis...\n\n';
    });

    try {
      await _diagnose();
    } catch (e) {
      _addOutput('\n❌ ERROR: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addOutput(String text) {
    setState(() {
      _output += '$text\n';
    });
    print(text);
  }

  Future<void> _diagnose() async {
    _addOutput('═══════════════════════════════════════════════════');
    _addOutput('🔍 FLAT MEMBERS DIAGNOSIS');
    _addOutput('═══════════════════════════════════════════════════\n');

    // Step 1: Get current user ID
    _addOutput('📋 STEP 1: Getting Current User ID');
    _addOutput('─────────────────────────────────────────────────\n');

    String? userId;
    
    // Try Firebase Auth
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _addOutput('✅ Firebase Auth User: ${firebaseUser.uid}');
      _addOutput('   Email: ${firebaseUser.email}');
      
      // Try to find user document by Firebase Auth UID
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        userId = doc.id;
        _addOutput('✅ Found user document by Firebase Auth UID');
      } else {
        // Try to find by authUid field
        _addOutput('🔍 Searching by authUid field...');
        final querySnapshot = await _firestore
            .collection('users')
            .where('authUid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          userId = querySnapshot.docs.first.id;
          _addOutput('✅ Found user document by authUid field');
        }
      }
    }
    
    // Fallback to SharedPreferences
    if (userId == null) {
      _addOutput('⚠️  No Firebase Auth user, checking SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id');
      
      if (userId == null) {
        _addOutput('❌ No user ID found!');
        return;
      }
      
      _addOutput('🆔 Using stored User ID: $userId');
    }

    _addOutput('\n🆔 Current User ID: $userId\n');

    // Step 2: Fetch current user data
    _addOutput('📋 STEP 2: Fetching Current User Data');
    _addOutput('─────────────────────────────────────────────────\n');

    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      _addOutput('❌ User document not found!');
      return;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final userFlatId = userData['flatId'];
    final userFlatLabel = userData['flatLabel'];
    final userAdminId = userData['adminId'];
    final userBuildingId = userData['buildingId'];
    final familyMembers = userData['familyMembers'];
    
    _addOutput('✅ User Data:');
    _addOutput('   Name: ${userData['name']}');
    _addOutput('   Email: ${userData['email']}');
    _addOutput('   Phone: ${userData['phone']}');
    _addOutput('   flatId: $userFlatId');
    _addOutput('   flatLabel: $userFlatLabel');
    _addOutput('   adminId: $userAdminId');
    _addOutput('   buildingId: $userBuildingId');
    _addOutput('   familyMembers: $familyMembers');
    _addOutput('   ownershipType: ${userData['ownershipType']}');

    if (userFlatId == null || userFlatId.isEmpty) {
      _addOutput('\n❌ No flatId found for user!');
      return;
    }

    // Step 3: Query users with same flatId
    _addOutput('\n📋 STEP 3: Querying Users with Same flatId');
    _addOutput('─────────────────────────────────────────────────\n');
    _addOutput('🔍 Query: users.where("flatId", isEqualTo: "$userFlatId")\n');

    final usersSnapshot = await _firestore
        .collection('users')
        .where('flatId', isEqualTo: userFlatId)
        .get();

    _addOutput('📊 Query Results: ${usersSnapshot.docs.length} documents found\n');

    if (usersSnapshot.docs.isEmpty) {
      _addOutput('❌ No users found with flatId: $userFlatId');
      _addOutput('\n💡 This means only your user document has this flatId.');
      _addOutput('   Family members might not have separate user accounts.');
    } else {
      for (var doc in usersSnapshot.docs) {
        final otherUserData = doc.data();
        final isSelf = doc.id == userId;
        
        _addOutput('${isSelf ? "👤" : "👥"} User: ${doc.id}');
        _addOutput('   Name: ${otherUserData['name']}');
        _addOutput('   Email: ${otherUserData['email']}');
        _addOutput('   flatId: ${otherUserData['flatId']}');
        _addOutput('   flatLabel: ${otherUserData['flatLabel']}');
        _addOutput('   adminId: ${otherUserData['adminId']}');
        _addOutput('   ${isSelf ? "(THIS IS YOU)" : ""}');
        _addOutput('');
      }
    }

    // Step 4: Check flats collection
    _addOutput('\n📋 STEP 4: Checking Flats Collection');
    _addOutput('─────────────────────────────────────────────────\n');

    if (userFlatId != null) {
      final flatDoc = await _firestore.collection('flats').doc(userFlatId).get();
      
      if (flatDoc.exists) {
        final flatData = flatDoc.data() as Map<String, dynamic>;
        _addOutput('✅ Flat Document Found:');
        _addOutput('   Flat ID: ${flatDoc.id}');
        _addOutput('   Flat Number: ${flatData['flatNumber']}');
        _addOutput('   Building ID: ${flatData['buildingId']}');
        _addOutput('   Owner Name: ${flatData['ownerName']}');
        _addOutput('   Residents: ${flatData['residents']}');
        
        // Check if residents field has data
        final residents = flatData['residents'];
        if (residents is List && residents.isNotEmpty) {
          _addOutput('\n   📋 Residents in flat:');
          for (var resident in residents) {
            _addOutput('      - $resident');
          }
        } else {
          _addOutput('   ⚠️  No residents array in flat document');
        }
      } else {
        _addOutput('❌ Flat document not found: $userFlatId');
      }
    }

    // Step 5: Summary and recommendations
    _addOutput('\n═══════════════════════════════════════════════════');
    _addOutput('📊 SUMMARY & RECOMMENDATIONS');
    _addOutput('═══════════════════════════════════════════════════\n');

    final otherUsersCount = usersSnapshot.docs.length - 1; // Exclude self
    
    if (otherUsersCount == 0) {
      _addOutput('❌ ISSUE FOUND: No other users with same flatId');
      _addOutput('\n💡 POSSIBLE CAUSES:');
      _addOutput('   1. Family members don\'t have separate user accounts');
      _addOutput('   2. Family members have different flatId values');
      _addOutput('   3. familyMembers field is just a count, not actual users');
      _addOutput('\n🔧 SOLUTIONS:');
      _addOutput('   Option A: Create separate user accounts for family members');
      _addOutput('   Option B: Store family members in a sub-collection');
      _addOutput('   Option C: Use the "residents" array in flats collection');
      _addOutput('   Option D: Create a "familyMembers" sub-collection under users');
    } else {
      _addOutput('✅ Found $otherUsersCount other user(s) with same flatId');
      _addOutput('   These should appear in the flat members list.');
    }

    _addOutput('\n═══════════════════════════════════════════════════');
    _addOutput('✅ DIAGNOSIS COMPLETE');
    _addOutput('═══════════════════════════════════════════════════');
  }
}
