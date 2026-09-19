// Quick check for amenities issue
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  print('\n🔍 AMENITIES DEBUG CHECK\n');
  print('=' * 50);
  
  // Check 1: User info
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ No user logged in!');
    return;
  }
  
  print('\n✅ User logged in:');
  print('   UID: ${user.uid}');
  print('   Email: ${user.email}');
  
  // Check 2: User document
  print('\n📋 Fetching user document...');
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  
  if (!userDoc.exists) {
    print('❌ User document not found!');
    return;
  }
  
  final userData = userDoc.data()!;
  print('✅ User document found:');
  print('   Name: ${userData['name']}');
  print('   Role: ${userData['role']}');
  print('   AdminId: ${userData['adminId']}');
  print('   AdminEmail: ${userData['adminEmail']}');
  print('   FlatId: ${userData['flatId']}');
  print('   FlatLabel: ${userData['flatLabel']}');
  
  // Check 3: All amenities
  print('\n📋 Fetching ALL amenities...');
  final allAmenities = await FirebaseFirestore.instance
      .collection('amenities')
      .get();
  
  print('✅ Total amenities in database: ${allAmenities.docs.length}');
  
  for (var doc in allAmenities.docs) {
    final data = doc.data();
    print('\n   📍 ${data['name']}');
    print('      ID: ${doc.id}');
    print('      AdminId: ${data['adminId']}');
    print('      AdminEmail: ${data['adminEmail']}');
    print('      IsActive: ${data['isActive']}');
    print('      Price: ${data['price']}');
  }
  
  // Check 4: Active amenities
  print('\n📋 Fetching ACTIVE amenities...');
  final activeAmenities = await FirebaseFirestore.instance
      .collection('amenities')
      .where('isActive', isEqualTo: true)
      .get();
  
  print('✅ Active amenities: ${activeAmenities.docs.length}');
  
  // Check 5: Try to match adminId
  final userAdminId = userData['adminId'];
  if (userAdminId != null && userAdminId.toString().isNotEmpty) {
    print('\n📋 Fetching amenities for adminId: $userAdminId');
    final matchedAmenities = await FirebaseFirestore.instance
        .collection('amenities')
        .where('adminId', isEqualTo: userAdminId)
        .where('isActive', isEqualTo: true)
        .get();
    
    print('✅ Matched amenities: ${matchedAmenities.docs.length}');
    
    if (matchedAmenities.docs.isEmpty) {
      print('\n⚠️  NO MATCH FOUND!');
      print('   User adminId: $userAdminId');
      print('   Amenity adminIds:');
      for (var doc in allAmenities.docs) {
        print('      - ${doc.data()['adminId']}');
      }
      print('\n💡 These values must match exactly!');
    }
  } else {
    print('\n⚠️  User has no adminId field!');
  }
  
  print('\n${'=' * 50}');
  print('✅ Check complete!\n');
}
