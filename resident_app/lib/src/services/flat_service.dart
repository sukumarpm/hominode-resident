// lib/src/services/flat_service.dart
// Firestore service for flat management

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/flat_model.dart';

class FlatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'flats';
  static const String usersCollection = 'users';

  /// Add a single flat
  Future<String?> addFlat(FlatModel flat) async {
    try {
      final docRef = await _firestore.collection(collectionName).add({
        'buildingId': flat.buildingId,
        'flatNumber': flat.flatNumber,
        'block': flat.block,
        'floor': flat.floor,
        'ownerId': flat.ownerId,
        'residentIds': flat.residentIds,
        'area': flat.area,
        'bedrooms': flat.bedrooms,
        'bathrooms': flat.bathrooms,
        'status': flat.status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Flat added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding flat: $e');
      return null;
    }
  }

  /// Bulk create flats
  Future<int> bulkCreateFlats({
    required String buildingId,
    required String block,
    required int startFloor,
    required int endFloor,
    required int flatsPerFloor,
    String flatNumberPrefix = '',
  }) async {
    try {
      int created = 0;
      final batch = _firestore.batch();

      for (int floor = startFloor; floor <= endFloor; floor++) {
        for (int flatNum = 1; flatNum <= flatsPerFloor; flatNum++) {
          final flatNumber = '$flatNumberPrefix${floor}0$flatNum';
          final docRef = _firestore.collection(collectionName).doc();

          batch.set(docRef, {
            'buildingId': buildingId,
            'flatNumber': flatNumber,
            'block': block,
            'floor': floor,
            'ownerId': null,
            'residentIds': [],
            'area': 0,
            'bedrooms': 0,
            'bathrooms': 0,
            'status': 'vacant',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          created++;
        }
      }

      await batch.commit();
      print('✅ Bulk created $created flats');
      return created;
    } catch (e) {
      print('❌ Error bulk creating flats: $e');
      return 0;
    }
  }

  /// Get all flats
  Future<List<FlatModel>> getFlats() async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('buildingId')
          .orderBy('floor')
          .orderBy('flatNumber')
          .get();

      final flats = snapshot.docs
          .map((doc) => FlatModel.fromSnapshot(doc))
          .toList();

      print('✅ Fetched ${flats.length} flats');
      return flats;
    } catch (e) {
      print('❌ Error fetching flats: $e');
      return [];
    }
  }

  /// Get flats by building
  Future<List<FlatModel>> getFlatsByBuilding(String buildingId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('buildingId', isEqualTo: buildingId)
          .get();

      final flats = snapshot.docs
          .map((doc) => FlatModel.fromSnapshot(doc))
          .toList();

      // Sort in memory
      flats.sort((a, b) {
        final floorCompare = a.floor.compareTo(b.floor);
        if (floorCompare != 0) return floorCompare;
        return a.flatNumber.compareTo(b.flatNumber);
      });

      print('✅ Fetched ${flats.length} flats for building $buildingId');
      return flats;
    } catch (e) {
      print('❌ Error fetching flats by building: $e');
      return [];
    }
  }

  /// Stream flats by building (real-time)
  Stream<List<FlatModel>> streamFlatsByBuilding(String buildingId) {
    return _firestore
        .collection(collectionName)
        .where('buildingId', isEqualTo: buildingId)
        .snapshots()
        .map((snapshot) {
          final flats = snapshot.docs
              .map((doc) => FlatModel.fromSnapshot(doc))
              .toList();

          // Sort in memory
          flats.sort((a, b) {
            final floorCompare = a.floor.compareTo(b.floor);
            if (floorCompare != 0) return floorCompare;
            return a.flatNumber.compareTo(b.flatNumber);
          });

          return flats;
        });
  }


  /// Update flat status
  Future<bool> updateFlatStatus(String flatId, String status) async {
    try {
      await _firestore.collection(collectionName).doc(flatId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Flat status updated: $flatId -> $status');
      return true;
    } catch (e) {
      print('❌ Error updating flat status: $e');
      return false;
    }
  }

  /// Assign resident to flat
  Future<bool> assignResident({
    required String flatId,
    required String residentId,
    required String buildingId,
  }) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();

      // Update flat: add resident and change status to occupied
      final flatRef = _firestore.collection(collectionName).doc(flatId);
      batch.update(flatRef, {
        'residentIds': FieldValue.arrayUnion([residentId]),
        'status': 'occupied',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user: set flatId and buildingId
      final userRef = _firestore.collection(usersCollection).doc(residentId);
      batch.update(userRef, {
        'flatId': flatId,
        'buildingId': buildingId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      print('✅ Resident assigned: $residentId -> Flat $flatId');
      return true;
    } catch (e) {
      print('❌ Error assigning resident: $e');
      return false;
    }
  }


  /// Remove resident from flat
  Future<bool> removeResident({
    required String flatId,
    required String residentId,
  }) async {
    try {
      // flat_service.dart
      debugPrint('🚨 removeResident CALLED for flatId=$flatId');
      debugPrintStack();
      // Start a batch write
      final batch = _firestore.batch();

      // Get flat to check remaining residents
      final flatDoc = await _firestore
          .collection(collectionName)
          .doc(flatId)
          .get();
      final flatData = flatDoc.data();
      final residentIds = List<String>.from(flatData?['residentIds'] ?? []);
      residentIds.remove(residentId);

      // Update flat: remove resident and update status if no residents left
      final flatRef = _firestore.collection(collectionName).doc(flatId);
      batch.update(flatRef, {
        'residentIds': FieldValue.arrayRemove([residentId]),
        'status': residentIds.isEmpty ? 'vacant' : 'occupied',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user: remove flatId and buildingId
      final userRef = _firestore.collection(usersCollection).doc(residentId);
      batch.update(userRef, {
        'flatId': FieldValue.delete(),
        'buildingId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      print('✅ Resident removed: $residentId from Flat $flatId');
      return true;
    } catch (e) {
      print('❌ Error removing resident: $e');
      return false;
    }
  }

  /// Update flat
  Future<bool> updateFlat(FlatModel flat) async {
    try {
      await _firestore.collection(collectionName).doc(flat.id).update({
        'buildingId': flat.buildingId,
        'flatNumber': flat.flatNumber,
        'block': flat.block,
        'floor': flat.floor,
        'area': flat.area,
        'bedrooms': flat.bedrooms,
        'bathrooms': flat.bathrooms,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Flat updated: ${flat.id}');
      return true;
    } catch (e) {
      print('❌ Error updating flat: $e');
      return false;
    }
  }

  /// Delete flat
  Future<bool> deleteFlat(String flatId) async {
    try {
      await _firestore.collection(collectionName).doc(flatId).delete();

      print('✅ Flat deleted: $flatId');
      return true;
    } catch (e) {
      print('❌ Error deleting flat: $e');
      return false;
    }
  }

  /// Get available residents (users without flatId)
  Future<List<Map<String, dynamic>>> getAvailableResidents() async {
    try {
      final snapshot = await _firestore
          .collection(usersCollection)
          .where('role', isEqualTo: 'resident')
          .get();

      final residents = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((user) => user['flatId'] == null)
          .toList();

      print('✅ Fetched ${residents.length} available residents');
      return residents;
    } catch (e) {
      print('❌ Error fetching available residents: $e');
      return [];
    }
  }

  /// Get resident details
  Future<Map<String, dynamic>?> getResidentDetails(String residentId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(residentId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        data?['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching resident details: $e');
      return null;
    }
  }
}
