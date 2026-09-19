// lib/src/services/complaint_firestore_service.dart
// Complaint Firestore Service - Save and manage complaint data

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint.dart';

/// Result class for complaint operations
class ComplaintResult {
  final bool success;
  final String? message;
  final String? complaintId;
  final String? errorCode;

  ComplaintResult({
    required this.success,
    this.message,
    this.complaintId,
    this.errorCode,
  });

  factory ComplaintResult.success({String? message, String? complaintId}) {
    return ComplaintResult(
      success: true,
      message: message ?? 'Operation successful',
      complaintId: complaintId,
    );
  }

  factory ComplaintResult.failure({
    required String message,
    String? errorCode,
  }) {
    return ComplaintResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Complaint Firestore Service
class ComplaintFirestoreService {
  // Singleton pattern
  static final ComplaintFirestoreService instance =
      ComplaintFirestoreService._internal();
  factory ComplaintFirestoreService() => instance;
  ComplaintFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name
  static const String complaintsCollection = 'complaints';

  // ============================================================================
  // CREATE COMPLAINT
  // ============================================================================

  /// Create a new complaint in Firestore
  /// Following the flow function pattern from UserDataService
  Future<ComplaintResult> createComplaint({
    required String title,
    required String description,
    required ComplaintCategory category,
  }) async {
    try {
      print('🔵 Creating complaint...');
      print('📝 Title: $title');
      print('📂 Category: ${category.categoryDisplayName}');

      // Get user ID using the same logic as UserDataService
      String? userId;

      // First try Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('🆔 ComplaintService: Firebase Auth User: ${firebaseUser.uid}');

        // Try to find user document by Firebase Auth UID
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          userId = doc.id;
          print('✅ ComplaintService: Found user document by Firebase Auth UID');
        } else {
          // Try to find by authUid field
          print('🔍 ComplaintService: Searching by authUid field...');
          final querySnapshot = await _firestore
              .collection('users')
              .where('authUid', isEqualTo: firebaseUser.uid)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            userId = querySnapshot.docs.first.id;
            print('✅ ComplaintService: Found user document by authUid field');
          }
        }
      }

      // Fallback to SharedPreferences
      if (userId == null) {
        print(
          '⚠️  ComplaintService: No Firebase Auth user, checking SharedPreferences...',
        );
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');

        if (userId == null) {
          print('❌ ComplaintService: No user ID found');
          return ComplaintResult.failure(
            message: 'No user is currently signed in',
            errorCode: 'not-authenticated',
          );
        }

        print('🆔 ComplaintService: Using stored User ID: $userId');
      }

      // Fetch user data from Firestore
      print('📥 Fetching user data from Firestore...');
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ User document not found in Firestore');
        print('   User ID: $userId');
        return ComplaintResult.failure(
          message: 'User account not found. Please log in again.',
          errorCode: 'user-not-found',
        );
      }

      final userData = userDoc.data();
      final userName =
          userData?['name'] ?? _auth.currentUser?.displayName ?? 'Unknown User';
      final userEmail = userData?['email'] ?? _auth.currentUser?.email ?? '';
      final flatId = userData?['flatId'] ?? '';
      final flatLabel = userData?['flatLabel'] ?? userData?['flatId'] ?? '';
      final adminId = userData?['adminId'];
      final communityId = userData?['communityId']?.toString().trim() ?? '';
      if (communityId.isEmpty) {
        return ComplaintResult.failure(
          message: 'Your resident account is not assigned to a community.',
          errorCode: 'community-not-assigned',
        );
      }

      print('✅ User data fetched: $userName ($userEmail)');
      print('🏢 Flat ID: $flatId');
      print('🏢 Flat Label: $flatLabel');
      print('👤 Admin ID: $adminId');

      // Create complaint document
      final complaintData = {
        'userId': _auth.currentUser?.uid ?? userId, // Use Firebase Auth UID
        'residentId':
            _auth.currentUser?.uid ??
            userId, // Also store as residentId for rules
        'userName': userName,
        'userEmail': userEmail,
        'flatId': flatId,
        'flatLabel': flatLabel,
        'adminId': adminId,
        'communityId': communityId,
        'title': title,
        'description': description,
        'category': category.name, // Store enum name
        'status': ComplaintStatus.pending.name, // Store enum name
        'assignedTo': null,
        'technicianPhone': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📦 Complaint data: $complaintData');

      // Add to Firestore
      final docRef = await _firestore
          .collection(complaintsCollection)
          .add(complaintData);

      print('✅ Complaint created successfully!');
      print('🆔 Complaint ID: ${docRef.id}');

      return ComplaintResult.success(
        message: 'Complaint submitted successfully',
        complaintId: docRef.id,
      );
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code}');
      print('❌ Message: ${e.message}');
      return ComplaintResult.failure(
        message: _getErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return ComplaintResult.failure(
        message: 'Failed to create complaint. Please try again.',
      );
    }
  }

  // ============================================================================
  // GET COMPLAINTS
  // ============================================================================

  /// Get all complaints for current user
  /// Following the flow function pattern from UserDataService
  Future<List<Complaint>> getMyComplaints() async {
    try {
      // Get user ID using the same logic as UserDataService
      String? userId;

      // First try Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('🆔 ComplaintService: Firebase Auth User: ${firebaseUser.uid}');

        // Try to find user document by Firebase Auth UID
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          userId = doc.id;
          print('✅ ComplaintService: Found user document by Firebase Auth UID');
        } else {
          // Try to find by authUid field
          print('🔍 ComplaintService: Searching by authUid field...');
          final querySnapshot = await _firestore
              .collection('users')
              .where('authUid', isEqualTo: firebaseUser.uid)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            userId = querySnapshot.docs.first.id;
            print('✅ ComplaintService: Found user document by authUid field');
          }
        }
      }

      // Fallback to SharedPreferences
      if (userId == null) {
        print(
          '⚠️  ComplaintService: No Firebase Auth user, checking SharedPreferences...',
        );
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');

        if (userId == null) {
          print('❌ ComplaintService: No user ID found');
          return [];
        }

        print('🆔 ComplaintService: Using stored User ID: $userId');
      }

      final authenticatedUid = _auth.currentUser?.uid;
      if (authenticatedUid == null || userId != authenticatedUid) {
        print('❌ ComplaintService: Canonical authenticated user unavailable');
        return [];
      }
      final profile = await _firestore
          .collection('users')
          .doc(authenticatedUid)
          .get();
      final communityId =
          profile.data()?['communityId']?.toString().trim() ?? '';
      if (!profile.exists || communityId.isEmpty) {
        print('❌ ComplaintService: Canonical community unavailable');
        return [];
      }

      final snapshot = await _firestore
          .collection(complaintsCollection)
          .where('communityId', isEqualTo: communityId)
          .where('userId', isEqualTo: authenticatedUid)
          .get();

      final complaints = snapshot.docs.map((doc) {
        return complaintFromFirestore(doc);
      }).toList();

      // Sort in memory by createdAt (newest first)
      complaints.sort((a, b) => b.createdDate.compareTo(a.createdDate));

      return complaints;
    } catch (e) {
      print('❌ Error fetching complaints: $e');
      return [];
    }
  }

  /// Get all complaints for admin (by adminId)
  /// Admin can see all complaints for flats they manage
  Future<List<Complaint>> getAdminComplaints() async {
    try {
      // Try to get user ID from Firebase Auth first
      String? userId;

      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
        print('🆔 Using Firebase Auth User ID: $userId');
      } else {
        // Fallback to Firestore-only authentication
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');

        if (userId == null) {
          print('❌ No user ID found');
          return [];
        }

        print('🆔 Using Firestore User ID: $userId');
      }

      // Check if user is admin
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ User document not found');
        return [];
      }

      final userData = userDoc.data();
      final userRole = userData?['role'] ?? 'resident';

      if (userRole != 'admin') {
        print('⚠️  User is not an admin, returning personal complaints only');
        return await getMyComplaints();
      }

      print('✅ User is admin, fetching all complaints for this admin');

      // Query complaints where adminId matches current user
      final snapshot = await _firestore
          .collection(complaintsCollection)
          .where('adminId', isEqualTo: userId)
          .get();

      final complaints = snapshot.docs.map((doc) {
        return complaintFromFirestore(doc);
      }).toList();

      // Sort in memory by createdAt (newest first)
      complaints.sort((a, b) => b.createdDate.compareTo(a.createdDate));

      print('✅ Found ${complaints.length} complaints for admin');

      return complaints;
    } catch (e) {
      print('❌ Error fetching admin complaints: $e');
      return [];
    }
  }

  /// Get complaints by flat ID
  /// Useful for admin to see complaints for a specific flat
  Future<List<Complaint>> getComplaintsByFlatId(String flatId) async {
    try {
      print('🔵 Fetching complaints for flat: $flatId');

      final snapshot = await _firestore
          .collection(complaintsCollection)
          .where('flatId', isEqualTo: flatId)
          .get();

      final complaints = snapshot.docs.map((doc) {
        return complaintFromFirestore(doc);
      }).toList();

      // Sort in memory by createdAt (newest first)
      complaints.sort((a, b) => b.createdDate.compareTo(a.createdDate));

      print('✅ Found ${complaints.length} complaints for flat $flatId');

      return complaints;
    } catch (e) {
      print('❌ Error fetching complaints by flat: $e');
      return [];
    }
  }

  /// Get complaints based on user role
  /// Automatically determines if user is admin or resident and returns appropriate data
  Future<List<Complaint>> getComplaintsForCurrentUser() async {
    try {
      // Try to get user ID from Firebase Auth first
      String? userId;

      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
      } else {
        // Fallback to Firestore-only authentication
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');

        if (userId == null) {
          print('❌ No user ID found');
          return [];
        }
      }

      // Check user role
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ User document not found');
        return [];
      }

      final userData = userDoc.data();
      final userRole = userData?['role'] ?? 'resident';

      if (userRole == 'admin') {
        print('👤 User is admin, fetching admin complaints');
        return await getAdminComplaints();
      } else {
        print('👤 User is resident, fetching personal complaints');
        return await getMyComplaints();
      }
    } catch (e) {
      print('❌ Error fetching complaints for current user: $e');
      return [];
    }
  }

  /// Stream complaints (real-time updates)
  /// Following the flow function pattern from UserDataService
  Stream<List<Complaint>> streamMyComplaints() async* {
    // Get user ID using the same logic as UserDataService
    String? userId;

    // First try Firebase Auth
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      print(
        '🆔 ComplaintService: Firebase Auth User for stream: ${firebaseUser.uid}',
      );

      // Try to find user document by Firebase Auth UID
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        userId = doc.id;
        print(
          '✅ ComplaintService: Found user document by Firebase Auth UID for stream',
        );
      } else {
        // Try to find by authUid field
        print('🔍 ComplaintService: Searching by authUid field for stream...');
        final querySnapshot = await _firestore
            .collection('users')
            .where('authUid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          userId = querySnapshot.docs.first.id;
          print(
            '✅ ComplaintService: Found user document by authUid field for stream',
          );
        }
      }
    }

    // Fallback to SharedPreferences
    if (userId == null) {
      print(
        '⚠️  ComplaintService: No Firebase Auth user, checking SharedPreferences for stream...',
      );
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id');

      if (userId == null) {
        print('❌ ComplaintService: No user ID found for stream');
        yield [];
        return;
      }

      print('🆔 ComplaintService: Using stored User ID for stream: $userId');
    }

    final authenticatedUid = _auth.currentUser?.uid;
    if (authenticatedUid == null || userId != authenticatedUid) {
      print('❌ ComplaintService: Canonical authenticated user unavailable');
      yield [];
      return;
    }
    final profile = await _firestore
        .collection('users')
        .doc(authenticatedUid)
        .get();
    final communityId = profile.data()?['communityId']?.toString().trim() ?? '';
    if (!profile.exists || communityId.isEmpty) {
      print('❌ ComplaintService: Canonical community unavailable');
      yield [];
      return;
    }

    yield* _firestore
        .collection(complaintsCollection)
        .where('communityId', isEqualTo: communityId)
        .where('userId', isEqualTo: authenticatedUid)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs.map((doc) {
            return complaintFromFirestore(doc);
          }).toList();

          // Sort in memory by createdAt (newest first)
          complaints.sort((a, b) => b.createdDate.compareTo(a.createdDate));

          return complaints;
        });
  }

  /// Stream admin complaints (real-time updates for admin)
  /// Following the flow function pattern from UserDataService
  Stream<List<Complaint>> streamAdminComplaints() async* {
    // Get user ID using the same logic as UserDataService
    String? userId;

    // First try Firebase Auth
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      print(
        '🆔 ComplaintService: Firebase Auth User for admin stream: ${firebaseUser.uid}',
      );

      // Try to find user document by Firebase Auth UID
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        userId = doc.id;
        print(
          '✅ ComplaintService: Found user document by Firebase Auth UID for admin stream',
        );
      } else {
        // Try to find by authUid field
        print(
          '🔍 ComplaintService: Searching by authUid field for admin stream...',
        );
        final querySnapshot = await _firestore
            .collection('users')
            .where('authUid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          userId = querySnapshot.docs.first.id;
          print(
            '✅ ComplaintService: Found user document by authUid field for admin stream',
          );
        }
      }
    }

    // Fallback to SharedPreferences
    if (userId == null) {
      print(
        '⚠️  ComplaintService: No Firebase Auth user, checking SharedPreferences for admin stream...',
      );
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id');

      if (userId == null) {
        print('❌ ComplaintService: No user ID found for admin stream');
        yield [];
        return;
      }

      print(
        '🆔 ComplaintService: Using stored User ID for admin stream: $userId',
      );
    }

    // Check if user is admin
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      print('❌ User document not found');
      yield [];
      return;
    }

    final userData = userDoc.data();
    final userRole = userData?['role'] ?? 'resident';

    if (userRole != 'admin') {
      print('⚠️  User is not an admin, returning personal complaints stream');
      yield* streamMyComplaints();
      return;
    }

    print('✅ User is admin, streaming all complaints for this admin');

    yield* _firestore
        .collection(complaintsCollection)
        .where('adminId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final complaints = snapshot.docs.map((doc) {
            return complaintFromFirestore(doc);
          }).toList();

          // Sort in memory by createdAt (newest first)
          complaints.sort((a, b) => b.createdDate.compareTo(a.createdDate));

          return complaints;
        });
  }

  /// Stream complaints based on user role
  Stream<List<Complaint>> streamComplaintsForCurrentUser() async* {
    // Try to get user ID from Firebase Auth first
    String? userId;

    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      userId = firebaseUser.uid;
    } else {
      // Fallback to Firestore-only authentication
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id');

      if (userId == null) {
        print('❌ No user ID found');
        yield [];
        return;
      }
    }

    // Check user role
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      print('❌ User document not found');
      yield [];
      return;
    }

    final userData = userDoc.data();
    final userRole = userData?['role'] ?? 'resident';

    if (userRole == 'admin') {
      print('👤 User is admin, streaming admin complaints');
      yield* streamAdminComplaints();
    } else {
      print('👤 User is resident, streaming personal complaints');
      yield* streamMyComplaints();
    }
  }

  // ============================================================================
  // UPDATE COMPLAINT
  // ============================================================================

  /// Update complaint status
  Future<ComplaintResult> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    try {
      await _firestore.collection(complaintsCollection).doc(complaintId).update(
        {'status': status.name, 'updatedAt': FieldValue.serverTimestamp()},
      );

      return ComplaintResult.success(message: 'Complaint status updated');
    } catch (e) {
      return ComplaintResult.failure(
        message: 'Failed to update complaint status',
      );
    }
  }

  /// Assign technician to complaint
  Future<ComplaintResult> assignTechnician({
    required String complaintId,
    required String technicianName,
    String? technicianPhone,
    String? staffId,
    String? staffRole,
  }) async {
    try {
      await _firestore
          .collection(complaintsCollection)
          .doc(complaintId)
          .update({
            'assignedTo': technicianName,
            'technicianPhone': technicianPhone,
            'assignedStaffId': staffId,
            'assignedStaffRole': staffRole,
            'status': ComplaintStatus.inProgress.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return ComplaintResult.success(message: 'Technician assigned');
    } catch (e) {
      return ComplaintResult.failure(message: 'Failed to assign technician');
    }
  }

  // ============================================================================
  // DELETE COMPLAINT
  // ============================================================================

  /// Delete complaint
  Future<ComplaintResult> deleteComplaint(String complaintId) async {
    try {
      await _firestore
          .collection(complaintsCollection)
          .doc(complaintId)
          .delete();

      return ComplaintResult.success(message: 'Complaint deleted');
    } catch (e) {
      return ComplaintResult.failure(message: 'Failed to delete complaint');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Convert Firestore document to Complaint object (public for real-time updates)
  Complaint complaintFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Debug logging
    print('🔍 Parsing complaint: ${doc.id}');
    print('📊 Raw status from Firestore: ${data['status']}');
    print('📊 Assigned to: ${data['assignedTo']}');
    print('📊 Staff ID: ${data['assignedStaffId']}');

    // Parse category enum
    ComplaintCategory category;
    try {
      category = ComplaintCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ComplaintCategory.other,
      );
    } catch (e) {
      category = ComplaintCategory.other;
    }

    // Parse status enum with detailed logging and support for multiple values
    ComplaintStatus status;
    try {
      final statusString = data['status'] as String?;
      final isResolved = data['isResolved'] as bool?;
      final resolvedAt = data['resolvedAt'];

      print('📊 Status string: "$statusString"');
      print('📊 isResolved: $isResolved');
      print('📊 resolvedAt: $resolvedAt');

      // Check if complaint is resolved (admin app might use isResolved field)
      if (isResolved == true || resolvedAt != null) {
        status = ComplaintStatus.completed;
        print('✅ Marked as completed (isResolved=true or resolvedAt exists)');
      }
      // Map different status values to our enum
      // Support both resident app and admin app status values
      else if (statusString == 'completed' ||
          statusString == 'resolved' ||
          statusString == 'closed') {
        status = ComplaintStatus.completed;
        print('✅ Mapped to: completed');
      } else if (statusString == 'inProgress' ||
          statusString == 'in_progress' ||
          statusString == 'in-progress' ||
          statusString == 'assigned') {
        status = ComplaintStatus.inProgress;
        print('✅ Mapped to: inProgress');
      } else if (statusString == 'pending' ||
          statusString == 'open' ||
          statusString == null) {
        status = ComplaintStatus.pending;
        print('✅ Mapped to: pending');
      } else {
        print('⚠️ Unknown status "$statusString", defaulting to pending');
        status = ComplaintStatus.pending;
      }

      print('✅ Final parsed status: $status');
    } catch (e) {
      print('❌ Error parsing status: $e');
      status = ComplaintStatus.pending;
    }

    // Parse createdAt timestamp
    DateTime createdDate;
    try {
      final timestamp = data['createdAt'] as Timestamp?;
      createdDate = timestamp?.toDate() ?? DateTime.now();
    } catch (e) {
      createdDate = DateTime.now();
    }

    final complaint = Complaint(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled',
      description: data['description'] as String? ?? '',
      category: category,
      status: status,
      createdDate: createdDate,
      assignedTo: data['assignedTo'] as String?,
      technicianPhone: data['technicianPhone'] as String?,
      assignedStaffId: data['assignedStaffId'] as String?,
      assignedStaffRole: data['assignedStaffRole'] as String?,
    );

    print('🎯 Final complaint status: ${complaint.status}');
    print('---');

    return complaint;
  }

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'permission-denied':
        return 'Permission denied. Please check your access rights.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Complaint not found.';
      case 'already-exists':
        return 'Complaint already exists.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
