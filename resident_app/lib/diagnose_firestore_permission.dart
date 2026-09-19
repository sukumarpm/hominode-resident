// lib/diagnose_firestore_permission.dart
// Diagnostic script to identify Firestore permission issues

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  print('🔍 Starting Firestore Permission Diagnostic...\n');
  
  await diagnoseFir estorePermissions();
}

Future<void> diagnoseFirestorePermissions() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  print('=' * 60);
  print('STEP 1: Check Firebase Auth Status');
  print('=' * 60);
  
  final User? currentUser = auth.currentUser;
  
  if (currentUser == null) {
    print('❌ NO USER LOGGED IN');
    print('   Problem: You must be logged in to access Firestore');
    print('   Solution: Login first before accessing data\n');
    return;
  }
  
  print('✅ User is logged in');
  print('   Firebase Auth UID: ${currentUser.uid}');
  print('   Email: ${currentUser.email ?? "No email"}');
  print('   Display Name: ${currentUser.displayName ?? "No name"}');
  print('   Email Verified: ${currentUser.emailVerified}');
  print('');
  
  print('=' * 60);
  print('STEP 2: Check User Document Exists');
  print('=' * 60);
  
  try {
    // Try to read user document using Firebase Auth UID
    print('📥 Attempting to read: users/${currentUser.uid}');
    
    final userDoc = await firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    if (!userDoc.exists) {
      print('❌ USER DOCUMENT NOT FOUND');
      print('   Document ID tried: ${currentUser.uid}');
      print('   Problem: User document does not exist in Firestore');
      print('   Solution: Create user document in Firestore\n');
      
      // Try to find by authUid field
      print('🔍 Searching for user by authUid field...');
      final querySnapshot = await firestore
          .collection('users')
          .where('authUid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('❌ No user found with authUid: ${currentUser.uid}');
        print('   Solution: Create user document with this structure:');
        print('   {');
        print('     "id": "${currentUser.uid}",');
        print('     "authUid": "${currentUser.uid}",');
        print('     "email": "${currentUser.email}",');
        print('     "name": "User Name",');
        print('     "phone": "+1234567890",');
        print('     "buildingId": "building1",');
        print('     "flatId": "flat101",');
        print('     "role": "resident",');
        print('     "createdAt": Timestamp.now()');
        print('   }\n');
      } else {
        print('✅ Found user document by authUid');
        print('   Document ID: ${querySnapshot.docs.first.id}');
        print('   Note: Document ID does not match Firebase Auth UID');
        print('   This may cause issues with security rules\n');
      }
      return;
    }
    
    print('✅ User document exists');
    final userData = userDoc.data()!;
    print('   Document ID: ${userDoc.id}');
    print('   Name: ${userData['name'] ?? "Missing"}');
    print('   Email: ${userData['email'] ?? "Missing"}');
    print('   Phone: ${userData['phone'] ?? "Missing"}');
    print('   Building ID: ${userData['buildingId'] ?? "❌ MISSING"}');
    print('   Flat ID: ${userData['flatId'] ?? "❌ MISSING"}');
    print('   Role: ${userData['role'] ?? "❌ MISSING"}');
    print('');
    
    // Check for required fields
    if (userData['buildingId'] == null) {
      print('⚠️  WARNING: buildingId is missing');
      print('   This will cause permission errors for building-specific data\n');
    }
    
    if (userData['flatId'] == null) {
      print('⚠️  WARNING: flatId is missing');
      print('   This will cause permission errors for flat-specific data\n');
    }
    
    if (userData['role'] == null) {
      print('⚠️  WARNING: role is missing');
      print('   This will cause permission errors for role-based access\n');
    }
    
  } catch (e) {
    print('❌ ERROR reading user document: $e');
    print('   This is the permission denied error!\n');
    
    if (e.toString().contains('permission-denied')) {
      print('🔍 DIAGNOSIS: Permission Denied Error');
      print('   Possible causes:');
      print('   1. Firestore rules not deployed correctly');
      print('   2. Rules deployed but not propagated yet (wait 2 minutes)');
      print('   3. User document ID does not match Firebase Auth UID');
      print('   4. Rules have syntax errors\n');
    }
  }
  
  print('=' * 60);
  print('STEP 3: Test Reading Other Collections');
  print('=' * 60);
  
  // Test bills collection
  print('📥 Testing bills collection...');
  try {
    final billsSnapshot = await firestore
        .collection('bills')
        .limit(1)
        .get();
    print('✅ Bills collection accessible (${billsSnapshot.docs.length} docs)');
  } catch (e) {
    print('❌ Bills collection: ${e.toString().contains('permission-denied') ? 'Permission Denied' : e}');
  }
  
  // Test complaints collection
  print('📥 Testing complaints collection...');
  try {
    final complaintsSnapshot = await firestore
        .collection('complaints')
        .limit(1)
        .get();
    print('✅ Complaints collection accessible (${complaintsSnapshot.docs.length} docs)');
  } catch (e) {
    print('❌ Complaints collection: ${e.toString().contains('permission-denied') ? 'Permission Denied' : e}');
  }
  
  // Test visitors collection
  print('📥 Testing visitors collection...');
  try {
    final visitorsSnapshot = await firestore
        .collection('visitors')
        .limit(1)
        .get();
    print('✅ Visitors collection accessible (${visitorsSnapshot.docs.length} docs)');
  } catch (e) {
    print('❌ Visitors collection: ${e.toString().contains('permission-denied') ? 'Permission Denied' : e}');
  }
  
  print('');
  
  print('=' * 60);
  print('STEP 4: Check Firestore Rules');
  print('=' * 60);
  
  print('⚠️  Cannot check rules from client');
  print('   Go to Firebase Console to verify:');
  print('   1. Rules are published');
  print('   2. No syntax errors');
  print('   3. Rules match the expected format\n');
  
  print('=' * 60);
  print('DIAGNOSIS COMPLETE');
  print('=' * 60);
  print('');
  
  print('📋 SUMMARY:');
  print('   - User logged in: ${'✅'}');
  print('   - User document exists: Check output above');
  print('   - Required fields present: Check output above');
  print('   - Collections accessible: Check output above');
  print('');
  
  print('🔧 NEXT STEPS:');
  print('   1. If user document missing: Create it in Firestore Console');
  print('   2. If required fields missing: Add buildingId, flatId, role');
  print('   3. If rules not working: Wait 2 minutes and try again');
  print('   4. If still failing: Check Firebase Console for rule errors');
  print('');
}
