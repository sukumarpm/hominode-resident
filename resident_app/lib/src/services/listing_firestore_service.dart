import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/listing_model.dart';
import 'content_moderation_service.dart';
import 'firestore_auth_service.dart';

class ListingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreAuthService _authService = FirestoreAuthService();

  // Get current user ID from either Firebase Auth or Firestore Auth Service
  Future<String> get _currentUserId async {
    // First try Firebase Auth
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      print('📥 Using Firebase Auth UID: ${firebaseUser.uid}');

      // Check if user document exists with this UID
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        return firebaseUser.uid;
      }

      // Try to find by authUid field
      final querySnapshot = await _firestore
          .collection('users')
          .where('authUid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
    }

    // Fallback to Firestore Auth Service (for Firestore-only login)
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      print('📥 Using Firestore Auth user ID: $userId');
      return userId;
    }

    print('❌ No user authenticated');
    return '';
  }

  // Get current user ID (public method)
  Future<String> getCurrentUserId() async {
    return await _currentUserId;
  }

  // Collection reference
  CollectionReference get _listingsCollection =>
      _firestore.collection('marketplaces');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // ============================================
  // CREATE LISTING
  // ============================================
  Future<ServiceResult> createListing({
    required String title,
    required int price,
    required String category,
    required String condition,
    required String description,
    List<String> images = const [],
  }) async {
    try {
      // Check content moderation first
      final moderationResult = await ContentModerationService().checkContent(
        text: '$title $description',
      );

      if (!moderationResult.isSafe) {
        print('⛔ Listing blocked by moderation: ${moderationResult.reason}');
        return ServiceResult(
          success: false,
          message: moderationResult.reason,
          data: 'MODERATION_BLOCKED',
        );
      }

      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) {
        return ServiceResult(success: false, message: 'User not authenticated');
      }

      print('📝 Creating listing: $title');

      // Fetch user data from Firestore
      final userDoc = await _usersCollection.doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final sellerName = userData?['name'] ?? 'Unknown Seller';

      // Check if user has building assigned
      final buildingId = userData?['buildingId'];
      if (buildingId == null || buildingId.toString().isEmpty) {
        print('❌ User has no building assigned');
        return ServiceResult(
          success: false,
          message: 'Cannot create listing: You must be assigned to a building',
        );
      }

      final listingData = {
        'title': title,
        'price': price,
        'category': category,
        'condition': condition,
        'description': description,
        'images': images,
        'sellerId': currentUserId,
        'sellerName': sellerName,
        'buildingId':
            buildingId, // Store by buildingId for building members only
        'status': 'active', // active, sold, deleted
        'phoneRequestCount': 0,
        'phoneRequestIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _listingsCollection.add(listingData);

      print('✅ Listing created with ID: ${docRef.id}');
      print('   Building ID: $buildingId');

      return ServiceResult(
        success: true,
        message: 'Listing created successfully',
        data: docRef.id,
      );
    } catch (e) {
      print('❌ Error creating listing: $e');
      return ServiceResult(
        success: false,
        message: 'Failed to create listing: ${e.toString()}',
      );
    }
  }

  // ============================================
  // GET ALL LISTINGS (FILTERED BY USER'S BUILDING)
  // ============================================
  Future<List<ListingModel>> getAllListings() async {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) {
        print('❌ User not authenticated');
        return [];
      }

      // Get current user's building ID
      final userDoc = await _usersCollection.doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userBuildingId = userData?['buildingId'];

      if (userBuildingId == null || userBuildingId.toString().isEmpty) {
        print('❌ User has no building assigned - cannot access listings');
        return [];
      }

      print('📥 Fetching listings for building: $userBuildingId');

      // Query listings for user's building only
      final querySnapshot = await _listingsCollection
          .where('buildingId', isEqualTo: userBuildingId)
          .where('status', isEqualTo: 'active')
          .get();

      final listings = querySnapshot.docs.map((doc) {
        return _listingFromFirestore(doc);
      }).toList();

      // Sort by createdAt in memory (newest first)
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
        '✅ Fetched ${listings.length} listings for building $userBuildingId',
      );
      return listings;
    } catch (e) {
      print('❌ Error fetching listings: $e');
      return [];
    }
  }

  // ============================================
  // GET LISTINGS BY CATEGORY (FILTERED BY USER'S BUILDING)
  // ============================================
  Future<List<ListingModel>> getListingsByCategory(String category) async {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) {
        print('❌ User not authenticated');
        return [];
      }

      // Get current user's building ID
      final userDoc = await _usersCollection.doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userBuildingId = userData?['buildingId'];

      if (userBuildingId == null || userBuildingId.toString().isEmpty) {
        print('❌ User has no building assigned - cannot access listings');
        return [];
      }

      print(
        '📥 Fetching listings for category: $category, building: $userBuildingId',
      );

      // Query listings for user's building only
      final querySnapshot = await _listingsCollection
          .where('buildingId', isEqualTo: userBuildingId)
          .where('status', isEqualTo: 'active')
          .where('category', isEqualTo: category)
          .get();

      final listings = querySnapshot.docs.map((doc) {
        return _listingFromFirestore(doc);
      }).toList();

      // Sort by createdAt in memory (newest first)
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Fetched ${listings.length} listings for category: $category');
      return listings;
    } catch (e) {
      print('❌ Error fetching listings by category: $e');
      return [];
    }
  }

  // ============================================
  // GET MY LISTINGS
  // ============================================
  Future<List<ListingModel>> getMyListings() async {
    try {
      final currentUserId = await _currentUserId;

      if (currentUserId.isEmpty) {
        print('⚠️ User not authenticated');
        return [];
      }

      print('📥 Fetching my listings...');

      // Get the resident's current building.
      // Marketplace access is building-scoped.
      final userSnapshot = await _usersCollection.doc(currentUserId).get();

      if (!userSnapshot.exists) {
        print('❌ User document not found');
        return [];
      }

      final userData = userSnapshot.data() as Map<String, dynamic>?;

      final userBuildingId = userData?['buildingId']?.toString().trim();

      if (userBuildingId == null || userBuildingId.isEmpty) {
        print('❌ User has no building assigned - cannot fetch my listings');
        return [];
      }

      print('   Seller ID: $currentUserId');
      print('   Building ID: $userBuildingId');

      // Important:
      // Query both seller ownership and tenant/building scope.
      final querySnapshot = await _listingsCollection
          .where('sellerId', isEqualTo: currentUserId)
          .where('buildingId', isEqualTo: userBuildingId)
          .get();

      final listings = querySnapshot.docs.map((doc) {
        return _listingFromFirestore(doc);
      }).toList();

      // Sort newest first in memory.
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Fetched ${listings.length} my listings');

      return listings;
    } catch (e) {
      print('❌ Error fetching my listings: $e');
      return [];
    }
  }

  // ============================================
  // STREAM ALL LISTINGS (FILTERED BY USER'S BUILDING)
  // ============================================
  Stream<List<ListingModel>> streamAllListings() async* {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) {
        print('❌ User not authenticated');
        yield [];
        return;
      }

      // Get user's building ID first
      await for (final userSnapshot
          in _usersCollection.doc(currentUserId).snapshots()) {
        if (!userSnapshot.exists) {
          print('❌ User document not found');
          yield [];
          continue;
        }

        final userData = userSnapshot.data() as Map<String, dynamic>?;
        final userBuildingId = userData?['buildingId'];

        if (userBuildingId == null || userBuildingId.toString().isEmpty) {
          print('❌ User has no building assigned - cannot access listings');
          yield [];
          continue;
        }

        print('📥 Streaming listings for building: $userBuildingId');

        // Stream listings for user's building only
        await for (final snapshot
            in _listingsCollection
                .where('buildingId', isEqualTo: userBuildingId)
                .where('status', isEqualTo: 'active')
                .snapshots()) {
          final listings = snapshot.docs.map((doc) {
            return _listingFromFirestore(doc);
          }).toList();

          // Sort by createdAt in memory (newest first)
          listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          yield listings;
        }
      }
    } catch (e) {
      print('❌ Error streaming listings: $e');
      yield [];
    }
  }

  // ============================================
  // UPDATE LISTING STATUS
  // ============================================
  Future<ServiceResult> updateListingStatus(
    String listingId,
    String status,
  ) async {
    try {
      print('🔄 Updating listing status: $listingId -> $status');

      await _listingsCollection.doc(listingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Listing status updated');

      return ServiceResult(success: true, message: 'Listing status updated');
    } catch (e) {
      print('❌ Error updating listing status: $e');
      return ServiceResult(
        success: false,
        message: 'Failed to update listing status: ${e.toString()}',
      );
    }
  }

  // ============================================
  // PHONE REQUEST OPERATIONS
  // ============================================

  /// Request phone number from seller
  /// Fetches requester details from users collection and validates building membership
  /// Creates request in subcollection: marketplaces/{productId}/requests
  Future<ServiceResult> requestPhoneNumber(String listingId) async {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) {
        return ServiceResult(success: false, message: 'User not authenticated');
      }

      print('📞 Requesting phone number for listing: $listingId');

      // Get listing details
      final listingDoc = await _listingsCollection.doc(listingId).get();
      final listingData = listingDoc.data() as Map<String, dynamic>?;
      final sellerId = listingData?['sellerId'];
      final buildingId = listingData?['buildingId'];

      if (sellerId == null || buildingId == null) {
        return ServiceResult(success: false, message: 'Listing not found');
      }

      // Get requester details from users collection
      final userDoc = await _usersCollection.doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        return ServiceResult(success: false, message: 'User not found');
      }

      // Validate that requester is in the same building as the listing
      final requesterBuildingId = userData['buildingId'];
      if (requesterBuildingId != buildingId) {
        return ServiceResult(
          success: false,
          message:
              'You must be a member of this building to request phone number',
        );
      }

      final requesterName = userData['name'] ?? 'Unknown';
      final requesterFlat = userData['flatLabel'] ?? 'N/A';
      final requesterPhone = userData['phone'] ?? '';

      // Check if already requested
      final existingRequest = await _firestore
          .collection('marketplaces')
          .doc(listingId)
          .collection('requests')
          .where('requesterId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return ServiceResult(
          success: false,
          message: 'You have already requested the phone number',
        );
      }

      // Create request in subcollection: marketplaces/{productId}/requests
      await _firestore
          .collection('marketplaces')
          .doc(listingId)
          .collection('requests')
          .add({
            'requesterId': currentUserId,
            'requesterName': requesterName,
            'requesterFlat': requesterFlat,
            'requesterPhone': requesterPhone,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ Phone request created in subcollection from building member');
      return ServiceResult(
        success: true,
        message: 'Phone request sent to seller',
      );
    } catch (e) {
      print('❌ Error requesting phone: $e');
      return ServiceResult(
        success: false,
        message: 'Failed to request phone number: ${e.toString()}',
      );
    }
  }

  /// Accept phone request (seller action)
  /// Updates status in subcollection: marketplaces/{productId}/requests/{requestId}
  Future<ServiceResult> acceptPhoneRequest(
    String listingId,
    String requestId,
  ) async {
    try {
      print('✅ Accepting phone request: $requestId');

      // Update the request status to accepted in subcollection
      await _firestore
          .collection('marketplaces')
          .doc(listingId)
          .collection('requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      print('✅ Phone request accepted');
      return ServiceResult(success: true, message: 'Phone request accepted');
    } catch (e) {
      print('❌ Error accepting phone request: $e');
      return ServiceResult(
        success: false,
        message: 'Failed to accept phone request: ${e.toString()}',
      );
    }
  }

  /// Reject phone request (seller action)
  /// Updates status in subcollection: marketplaces/{productId}/requests/{requestId}
  Future<ServiceResult> rejectPhoneRequest(
    String listingId,
    String requestId,
  ) async {
    try {
      print('❌ Rejecting phone request: $requestId');

      await _firestore
          .collection('marketplaces')
          .doc(listingId)
          .collection('requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      print('✅ Phone request rejected');
      return ServiceResult(success: true, message: 'Phone request rejected');
    } catch (e) {
      print('❌ Error rejecting phone request: $e');
      return ServiceResult(
        success: false,
        message: 'Failed to reject phone request: ${e.toString()}',
      );
    }
  }

  /// Stream phone requests for real-time updates from subcollection
  /// Fetches from: marketplaces/{productId}/requests
  Stream<List<Map<String, dynamic>>> streamPhoneRequestsForListing(
    String listingId,
  ) async* {
    try {
      print(
        '📞 Streaming phone requests from subcollection for listing: $listingId',
      );

      await for (final snapshot
          in _firestore
              .collection('marketplaces')
              .doc(listingId)
              .collection('requests')
              .orderBy('createdAt', descending: true)
              .snapshots()) {
        final requestsList = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          requestsList.add({...data, 'id': doc.id, 'requestId': doc.id});
        }

        print('✅ Fetched ${requestsList.length} requests from subcollection');
        yield requestsList;
      }
    } catch (e) {
      print('❌ Error streaming phone requests: $e');
      yield [];
    }
  }

  // ============================================
  // UPDATE LISTING
  // ============================================
  Future<ServiceResult> updateListing({
    required String listingId,
    required String title,
    required int price,
    required String category,
    required String condition,
    required String description,
    List<String>? images,
  }) async {
    try {
      print('🔄 Updating listing: $listingId');

      final updateData = {
        'title': title,
        'price': price,
        'category': category,
        'condition': condition,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (images != null) {
        updateData['images'] = images;
      }

      await _listingsCollection.doc(listingId).update(updateData);

      print('✅ Listing updated');
      return ServiceResult(
        success: true,
        message: 'Listing updated successfully',
      );
    } catch (e) {
      print('❌ Error updating listing: $e');
      return ServiceResult(
        success: false,
        message: 'Failed to update listing: ${e.toString()}',
      );
    }
  }

  // ============================================
  // DELETE LISTING
  // ============================================
  Future<ServiceResult> deleteListing(String listingId) async {
    try {
      print('🗑️ Deleting listing: $listingId');

      // Soft delete by updating status
      await _listingsCollection.doc(listingId).update({
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Listing deleted');

      return ServiceResult(
        success: true,
        message: 'Listing deleted successfully',
      );
    } catch (e) {
      print('❌ Error deleting listing: $e');
      return ServiceResult(
        success: false,
        message: 'Failed to delete listing: ${e.toString()}',
      );
    }
  }

  /// Get accepted phone numbers for a buyer (buyer view)
  /// Fetches from subcollection: marketplaces/{productId}/requests
  /// Returns seller's phone number when request is accepted
  Future<List<Map<String, dynamic>>> getAcceptedPhoneNumbersForBuyer(
    String listingId,
  ) async {
    try {
      final currentUserId = await _currentUserId;
      if (currentUserId.isEmpty) {
        return [];
      }

      print('📞 Fetching accepted phone numbers for buyer: $currentUserId');

      // Get listing details (seller info)
      final listingDoc = await _listingsCollection.doc(listingId).get();
      final listingData = listingDoc.data() as Map<String, dynamic>?;
      final sellerName = listingData?['sellerName'] ?? 'Unknown';
      final sellerId = listingData?['sellerId'];

      if (listingData == null || sellerId == null) {
        return [];
      }

      // Check if this buyer's request was accepted in subcollection
      final querySnapshot = await _firestore
          .collection('marketplaces')
          .doc(listingId)
          .collection('requests')
          .where('requesterId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ No accepted phone request found for this buyer');
        return [];
      }

      // Get seller's phone number from users collection
      final sellerDoc = await _usersCollection.doc(sellerId).get();
      final sellerData = sellerDoc.data() as Map<String, dynamic>?;
      final sellerPhone = sellerData?['phone'] ?? '';

      print('✅ Fetched seller phone number for buyer');
      return [
        {'phone': sellerPhone, 'sellerName': sellerName},
      ];
    } catch (e) {
      print('❌ Error fetching accepted phone numbers for buyer: $e');
      return [];
    }
  }

  /// Get history listings (sold/deleted) for current user
  Future<List<ListingModel>> getHistoryListings() async {
    try {
      final currentUserId = await _currentUserId;

      if (currentUserId.isEmpty) {
        print('⚠️ User not authenticated');
        return [];
      }

      print('📥 Fetching history listings...');

      // Get resident's current building.
      final userSnapshot = await _usersCollection.doc(currentUserId).get();

      if (!userSnapshot.exists) {
        print('❌ User document not found');
        return [];
      }

      final userData = userSnapshot.data() as Map<String, dynamic>?;

      final userBuildingId = userData?['buildingId']?.toString().trim();

      if (userBuildingId == null || userBuildingId.isEmpty) {
        print('❌ User has no building assigned - cannot fetch history');
        return [];
      }

      print('   Seller ID: $currentUserId');
      print('   Building ID: $userBuildingId');

      final querySnapshot = await _listingsCollection
          .where('sellerId', isEqualTo: currentUserId)
          .where('buildingId', isEqualTo: userBuildingId)
          .get();

      final listings = querySnapshot.docs.map((doc) {
        return _listingFromFirestore(doc);
      }).toList();

      // Only completed/removed listings belong in History.
      final historyListings = listings.where((listing) {
        return listing.status == 'sold' || listing.status == 'deleted';
      }).toList();

      // Newest history entry first.
      historyListings.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      print('✅ Fetched ${historyListings.length} history listings');

      return historyListings;
    } catch (e) {
      print('❌ Error fetching history listings: $e');
      return [];
    }
  }

  // ============================================
  // HELPER: CONVERT FIRESTORE DOC TO MODEL
  // ============================================
  ListingModel _listingFromFirestore(DocumentSnapshot doc) {
    return ListingModel.fromFirestore(doc);
  }
}

// ============================================
// SERVICE RESULT CLASS
// ============================================
class ServiceResult {
  final bool success;
  final String? message;
  final dynamic data;

  ServiceResult({required this.success, this.message, this.data});
}
