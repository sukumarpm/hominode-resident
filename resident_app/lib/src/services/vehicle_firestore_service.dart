// lib/src/services/vehicle_firestore_service.dart
// Firestore service for vehicles

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';

class VehicleFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String collectionName = 'vehicles';

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  Future<String?> _communityId() async {
    final uid = _userId;
    if (uid == null) return null;
    final profile = await _firestore.collection('users').doc(uid).get();
    final communityId = profile.data()?['communityId']?.toString().trim();
    return communityId == null || communityId.isEmpty ? null : communityId;
  }

  /// Add a new vehicle
  Future<String?> addVehicle(Vehicle vehicle) async {
    try {
      final communityId = await _communityId();
      if (_userId == null || communityId == null) {
        print('❌ No user logged in');
        return null;
      }

      final docRef = await _firestore.collection(collectionName).add({
        'userId': _userId,
        'communityId': communityId,
        'name': vehicle.name,
        'type': vehicle.type,
        'plateNumber': vehicle.plateNumber,
        'color': vehicle.color,
        'photoUrl': vehicle.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Vehicle added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding vehicle: $e');
      return null;
    }
  }

  /// Get all vehicles for current user
  Future<List<Vehicle>> getVehicles() async {
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

      final vehicles = snapshot.docs.map((doc) {
        final data = doc.data();
        return Vehicle(
          id: doc.id,
          name: data['name'] ?? '',
          type: data['type'] ?? '',
          plateNumber: data['plateNumber'] ?? '',
          color: data['color'] ?? '',
          photoUrl: data['photoUrl'],
        );
      }).toList();

      print('✅ Fetched ${vehicles.length} vehicles');
      return vehicles;
    } catch (e) {
      print('❌ Error fetching vehicles: $e');
      return [];
    }
  }

  /// Stream vehicles (real-time updates)
  Stream<List<Vehicle>> streamVehicles() async* {
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
            return Vehicle(
              id: doc.id,
              name: data['name'] ?? '',
              type: data['type'] ?? '',
              plateNumber: data['plateNumber'] ?? '',
              color: data['color'] ?? '',
              photoUrl: data['photoUrl'],
            );
          }).toList();
        });
  }

  /// Update vehicle
  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      if (_userId == null) {
        print('❌ No user logged in');
        return false;
      }

      await _firestore.collection(collectionName).doc(vehicle.id).update({
        'name': vehicle.name,
        'type': vehicle.type,
        'plateNumber': vehicle.plateNumber,
        'color': vehicle.color,
        'photoUrl': vehicle.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Vehicle updated: ${vehicle.id}');
      return true;
    } catch (e) {
      print('❌ Error updating vehicle: $e');
      return false;
    }
  }

  /// Delete vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      if (_userId == null) {
        print('❌ No user logged in');
        return false;
      }

      await _firestore.collection(collectionName).doc(vehicleId).delete();

      print('✅ Vehicle deleted: $vehicleId');
      return true;
    } catch (e) {
      print('❌ Error deleting vehicle: $e');
      return false;
    }
  }
}
