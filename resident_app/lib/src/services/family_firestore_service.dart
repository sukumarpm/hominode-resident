// lib/src/services/family_firestore_service.dart
// Firestore service for family members

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_member.dart';

class FamilyFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String collectionName = 'familyMembers';

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  Future<String?> _communityId() async {
    final uid = _userId;
    if (uid == null) return null;
    final profile = await _firestore.collection('users').doc(uid).get();
    final communityId = profile.data()?['communityId']?.toString().trim();
    return communityId == null || communityId.isEmpty ? null : communityId;
  }

  /// Add a new family member
  Future<String?> addFamilyMember(FamilyMember member) async {
    try {
      final communityId = await _communityId();
      if (_userId == null || communityId == null) {
        print('❌ No user logged in');
        return null;
      }

      final docRef = await _firestore.collection(collectionName).add({
        'userId': _userId,
        'communityId': communityId,
        'name': member.name,
        'relation': member.relation,
        'age': member.age,
        'photoUrl': member.photoUrl,
        'isPrimary': member.isPrimary,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Family member added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding family member: $e');
      return null;
    }
  }

  /// Get all family members for current user
  Future<List<FamilyMember>> getFamilyMembers() async {
    try {
      final communityId = await _communityId();
      if (_userId == null || communityId == null) {
        print('❌ No user logged in');
        return [];
      }

      final snapshot = await _firestore
          .collection(collectionName)
          .where('communityId', isEqualTo: communityId)
          .where('userId', isEqualTo: _userId)
          .get();

      final members = snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyMember(
          id: doc.id,
          name: data['name'] ?? '',
          relation: data['relation'] ?? '',
          age: data['age'] ?? 0,
          photoUrl: data['photoUrl'],
          isPrimary: data['isPrimary'] ?? false,
        );
      }).toList();

      print('✅ Fetched ${members.length} family members');
      return members;
    } catch (e) {
      print('❌ Error fetching family members: $e');
      return [];
    }
  }

  /// Stream family members (real-time updates)
  Stream<List<FamilyMember>> streamFamilyMembers() async* {
    final communityId = await _communityId();
    if (_userId == null) {
      yield [];
      return;
    }

    if (communityId == null) {
      yield [];
      return;
    }

    yield* _firestore
        .collection(collectionName)
        .where('communityId', isEqualTo: communityId)
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return FamilyMember(
              id: doc.id,
              name: data['name'] ?? '',
              relation: data['relation'] ?? '',
              age: data['age'] ?? 0,
              photoUrl: data['photoUrl'],
              isPrimary: data['isPrimary'] ?? false,
            );
          }).toList();
        });
  }

  /// Update family member
  Future<bool> updateFamilyMember(FamilyMember member) async {
    try {
      if (_userId == null) {
        print('❌ No user logged in');
        return false;
      }

      await _firestore.collection(collectionName).doc(member.id).update({
        'name': member.name,
        'relation': member.relation,
        'age': member.age,
        'photoUrl': member.photoUrl,
        'isPrimary': member.isPrimary,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Family member updated: ${member.id}');
      return true;
    } catch (e) {
      print('❌ Error updating family member: $e');
      return false;
    }
  }

  /// Delete family member
  Future<bool> deleteFamilyMember(String memberId) async {
    try {
      if (_userId == null) {
        print('❌ No user logged in');
        return false;
      }

      await _firestore.collection(collectionName).doc(memberId).delete();

      print('✅ Family member deleted: $memberId');
      return true;
    } catch (e) {
      print('❌ Error deleting family member: $e');
      return false;
    }
  }
}
