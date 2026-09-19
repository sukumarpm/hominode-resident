import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/marketplace_request_model.dart';
import 'firestore_auth_service.dart';

class MarketplaceRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreAuthService _authService = FirestoreAuthService();

  // Get current user ID
  Future<String> get _currentUserId async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        return firebaseUser.uid;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('authUid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
    }

    final userId = await _authService.getCurrentUserId();
    return userId ?? '';
  }

  // Request phone number
  Future<bool> requestPhoneNumber({
    required String productId,
    required String productOwnerId,
    required String buildingId,
  }) async {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) {
        print('❌ User not authenticated');
        return false;
      }

      // Prevent seller from requesting their own phone
      if (currentUserId == productOwnerId) {
        print('❌ Seller cannot request their own phone number');
        return false;
      }

      // Get current user details
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Unknown';
      final userFlat = userData?['flatLabel'] ?? 'N/A';
      final userPhone = userData?['phone'] as String? ?? '';

      // Validate user has phone number
      if (userPhone.isEmpty) {
        print('❌ User phone number not found');
        return false;
      }

      // Check if already requested
      final existingRequest = await _firestore
          .collection('marketplaceRequests')
          .where('productId', isEqualTo: productId)
          .where('requestUserId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        print('⚠️ Already requested phone for this product');
        return false;
      }

      // Create request in transaction for atomicity
      await _firestore.runTransaction((transaction) async {
        // Create request document
        final requestRef = _firestore.collection('marketplaceRequests').doc();
        transaction.set(requestRef, {
          'productId': productId,
          'productOwnerId': productOwnerId,
          'requestUserId': currentUserId,
          'requestUserName': userName,
          'requestUserFlat': userFlat,
          'requestUserPhone': userPhone,
          'buildingId': buildingId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('✅ Phone request created');
      return true;
    } catch (e) {
      print('❌ Error requesting phone: $e');
      return false;
    }
  }

  // Get requests for a product (for product owner)
  Stream<List<MarketplaceRequestModel>> getRequestsForProduct(
    String productId,
  ) {
    return _firestore
        .collection('marketplaceRequests')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MarketplaceRequestModel.fromFirestore(doc))
              .toList();
        });
  }

  // Accept request
  Future<bool> acceptRequest(String requestId) async {
    try {
      await _firestore.collection('marketplaceRequests').doc(requestId).update({
        'status': 'accepted',
      });
      print('✅ Request accepted');
      return true;
    } catch (e) {
      print('❌ Error accepting request: $e');
      return false;
    }
  }

  // Reject request
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _firestore.collection('marketplaceRequests').doc(requestId).update({
        'status': 'rejected',
      });
      print('✅ Request rejected');
      return true;
    } catch (e) {
      print('❌ Error rejecting request: $e');
      return false;
    }
  }

  // Get accepted phone number for buyer
  Future<String?> getAcceptedPhoneNumber({
    required String productId,
    required String productOwnerId,
  }) async {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) return null;

      final request = await _firestore
          .collection('marketplaceRequests')
          .where('productId', isEqualTo: productId)
          .where('productOwnerId', isEqualTo: productOwnerId)
          .where('requestUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (request.docs.isEmpty) return null;

      // Get owner's phone
      final ownerDoc = await _firestore
          .collection('users')
          .doc(productOwnerId)
          .get();
      final ownerData = ownerDoc.data();
      final phone = ownerData?['phone'] as String?;

      // Validate phone is not empty
      if (phone == null || phone.isEmpty) {
        print('⚠️ Seller phone number is empty');
        return null;
      }

      return phone;
    } catch (e) {
      print('❌ Error getting phone: $e');
      return null;
    }
  }

  // Check if user already requested
  Future<bool> hasUserRequested({required String productId}) async {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) return false;

      final request = await _firestore
          .collection('marketplaceRequests')
          .where('productId', isEqualTo: productId)
          .where('requestUserId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return request.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking request: $e');
      return false;
    }
  }

  // Get request count for product
  Future<int> getRequestCount(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('marketplaceRequests')
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting request count: $e');
      return 0;
    }
  }
}
