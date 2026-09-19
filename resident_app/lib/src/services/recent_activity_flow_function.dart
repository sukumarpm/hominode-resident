// lib/src/services/recent_activity_flow_function.dart
// Recent Activity Flow Function - Fetches real data from Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Activity item model
class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String statusText;
  final String
  activityType; // 'booking', 'package', 'visitor', 'complaint', 'payment'
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.activityType,
    required this.timestamp,
    required this.data,
  });

  factory ActivityItem.fromBooking(Map<String, dynamic> data, String docId) {
    final timestamp =
        (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ActivityItem(
      id: docId,
      title: '${data['amenityName'] ?? 'Amenity'} Booked',
      subtitle: _formatDate(timestamp),
      statusText: data['status'] ?? 'Pending',
      activityType: 'booking',
      timestamp: timestamp,
      data: data,
    );
  }

  factory ActivityItem.fromVisitor(Map<String, dynamic> data, String docId) {
    final timestamp =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ActivityItem(
      id: docId,
      title: 'Visitor - ${data['visitorName'] ?? 'Unknown'}',
      subtitle: '${data['visitorPhone'] ?? ''} - ${_formatDate(timestamp)}',
      statusText: data['status'] ?? 'Pending',
      activityType: 'visitor',
      timestamp: timestamp,
      data: data,
    );
  }

  factory ActivityItem.fromComplaint(Map<String, dynamic> data, String docId) {
    final timestamp =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ActivityItem(
      id: docId,
      title: 'Complaint - ${data['category'] ?? 'General'}',
      subtitle:
          '${(() {
            final description = data['description']?.toString() ?? '';
            return description.length > 30 ? '${description.substring(0, 30)}...' : description;
          })()} - ${_formatDate(timestamp)}',
      statusText: data['status'] ?? 'Open',
      activityType: 'complaint',
      timestamp: timestamp,
      data: data,
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Recent Activity Result
class RecentActivityResult {
  final bool success;
  final String? message;
  final List<ActivityItem> activities;
  final String? errorCode;

  RecentActivityResult({
    required this.success,
    this.message,
    this.activities = const [],
    this.errorCode,
  });

  factory RecentActivityResult.success({
    String? message,
    required List<ActivityItem> activities,
  }) {
    return RecentActivityResult(
      success: true,
      message: message ?? 'Activities fetched successfully',
      activities: activities,
    );
  }

  factory RecentActivityResult.failure({
    required String message,
    String? errorCode,
  }) {
    return RecentActivityResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Recent Activity Flow Function Service
class RecentActivityFlowFunction {
  static final RecentActivityFlowFunction instance =
      RecentActivityFlowFunction._internal();
  factory RecentActivityFlowFunction() => instance;
  RecentActivityFlowFunction._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // MAIN FLOW FUNCTION: Fetch Recent Activities
  // ============================================================================

  /// Complete recent activity fetch flow function
  /// Step 1: Validate user authentication
  /// Step 2: Get user flat ID
  /// Step 3: Fetch bookings from Firestore
  /// Step 4: Fetch visitors from Firestore
  /// Step 5: Fetch complaints from Firestore
  /// Step 6: Combine and sort by timestamp
  /// Step 7: Return recent activities (limit 5)
  Future<RecentActivityResult> fetchRecentActivities({int limit = 5}) async {
    try {
      print('🔵 RECENT ACTIVITY FLOW: Starting fetch...');

      // ========================================================================
      // STEP 1: Validate User Authentication
      // ========================================================================
      print('🔐 STEP 1: Validating user authentication...');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ STEP 1 FAILED: User not authenticated');
        return RecentActivityResult.failure(
          message: 'User not authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        );
      }

      print('✅ STEP 1 PASSED: User authenticated');
      print('   User ID: $userId');

      // ========================================================================
      // STEP 2: Get User Flat ID
      // ========================================================================
      print('🔐 STEP 2: Getting user flat ID...');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ STEP 2 FAILED: User document not found');
        return RecentActivityResult.failure(
          message: 'User document not found',
          errorCode: 'USER_NOT_FOUND',
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final flatId = userData['flatId'] as String?;
      final buildingId = userData['buildingId'] as String?;
      final communityId = userData['communityId'] as String?;

      if (flatId == null ||
          buildingId == null ||
          communityId == null ||
          communityId.isEmpty) {
        print('❌ STEP 2 FAILED: Flat ID or Building ID not found');
        return RecentActivityResult.failure(
          message: 'Flat ID or Building ID not found in user document',
          errorCode: 'FLAT_ID_NOT_FOUND',
        );
      }

      print('✅ STEP 2 PASSED: User flat ID retrieved');
      print('   Flat ID: $flatId');
      print('   Building ID: $buildingId');

      // ========================================================================
      // STEP 3: Fetch Bookings from Firestore
      // ========================================================================
      print('🔐 STEP 3: Fetching bookings...');

      final List<ActivityItem> activities = [];

      try {
        final bookingsQuery = await _firestore
            .collection('bookings')
            .where('communityId', isEqualTo: communityId)
            .where('flatId', isEqualTo: flatId)
            .orderBy('bookingDate', descending: true)
            .limit(10)
            .get();

        print('   Found ${bookingsQuery.docs.length} bookings');

        for (final doc in bookingsQuery.docs) {
          final data = doc.data();
          activities.add(ActivityItem.fromBooking(data, doc.id));
        }

        print('✅ STEP 3 PASSED: Bookings fetched');
      } catch (e) {
        print('⚠️  STEP 3 WARNING: Error fetching bookings: $e');
      }

      // ========================================================================
      // STEP 4: Fetch Visitors from Firestore
      // ========================================================================
      print('🔐 STEP 4: Fetching visitors...');

      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid == null) {
          throw StateError('Resident is not authenticated.');
        }

        final visitorsQuery = await _firestore
            .collection('visitors')
            .where('communityId', isEqualTo: communityId)
            .where('hostUserId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        print('   Found ${visitorsQuery.docs.length} visitors');

        for (final doc in visitorsQuery.docs) {
          final data = doc.data();
          activities.add(ActivityItem.fromVisitor(data, doc.id));
        }

        print('✅ STEP 4 PASSED: Visitors fetched');
      } catch (e) {
        print('⚠️  STEP 4 WARNING: Error fetching visitors: $e');
      }

      // ========================================================================
      // STEP 5: Fetch Complaints from Firestore
      // ========================================================================
      print('🔐 STEP 5: Fetching complaints...');

      try {
        final authenticatedUid = _auth.currentUser?.uid;

        if (authenticatedUid == null) {
          print('⚠️  STEP 5 WARNING: No authenticated user for complaints');
        } else {
          final complaintsQuery = await _firestore
              .collection('complaints')
              .where('communityId', isEqualTo: communityId)
              .where('userId', isEqualTo: authenticatedUid)
              .get();

          print('   Found ${complaintsQuery.docs.length} complaints');

          final complaintDocs = complaintsQuery.docs.toList()
            ..sort((a, b) {
              final aCreatedAt = a.data()['createdAt'] as Timestamp?;
              final bCreatedAt = b.data()['createdAt'] as Timestamp?;

              if (aCreatedAt == null && bCreatedAt == null) return 0;
              if (aCreatedAt == null) return 1;
              if (bCreatedAt == null) return -1;

              return bCreatedAt.compareTo(aCreatedAt);
            });

          for (final doc in complaintDocs.take(10)) {
            final data = doc.data();
            activities.add(ActivityItem.fromComplaint(data, doc.id));
          }

          print('✅ STEP 5 PASSED: Complaints fetched');
        }
      } catch (e) {
        print('⚠️  STEP 5 WARNING: Error fetching complaints: $e');
      }

      // ========================================================================
      // STEP 6: Combine and Sort by Timestamp
      // ========================================================================
      print('🔐 STEP 6: Combining and sorting activities...');

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('✅ STEP 6 PASSED: Activities sorted');
      print('   Total activities: ${activities.length}');

      // ========================================================================
      // STEP 7: Return Recent Activities (Limit)
      // ========================================================================
      print('🔐 STEP 7: Limiting to $limit activities...');

      final recentActivities = activities.take(limit).toList();

      print('✅ STEP 7 PASSED: Recent activities limited');
      print('   Returning ${recentActivities.length} activities');
      print('✅ RECENT ACTIVITY FLOW: SUCCESS');

      return RecentActivityResult.success(
        message: 'Recent activities fetched successfully',
        activities: recentActivities,
      );
    } catch (e, stackTrace) {
      print('❌ RECENT ACTIVITY FLOW: Unexpected error: $e');
      print('   Stack trace: $stackTrace');
      return RecentActivityResult.failure(
        message: 'Failed to fetch recent activities: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }

  // ============================================================================
  // STREAM RECENT ACTIVITIES (Real-time)
  // ============================================================================

  /// Stream recent activities in real-time
  Stream<RecentActivityResult> streamRecentActivities({int limit = 5}) async* {
    try {
      print('🔵 Setting up recent activities stream...');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        yield RecentActivityResult.failure(
          message: 'User not authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        );
        return;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        yield RecentActivityResult.failure(
          message: 'User document not found',
          errorCode: 'USER_NOT_FOUND',
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final flatId = userData['flatId'] as String?;
      final communityId = userData['communityId'] as String?;

      if (flatId == null || communityId == null || communityId.isEmpty) {
        yield RecentActivityResult.failure(
          message: 'Flat ID not found',
          errorCode: 'FLAT_ID_NOT_FOUND',
        );
        return;
      }

      print('   Flat ID: $flatId');
      print('   Setting up streams for bookings, visitors, and complaints...');

      // Combine streams from multiple collections
      final bookingsStream = _firestore
          .collection('bookings')
          .where('communityId', isEqualTo: communityId)
          .where('flatId', isEqualTo: flatId)
          .orderBy('bookingDate', descending: true)
          .limit(10)
          .snapshots();

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw StateError('Resident is not authenticated.');
      }

      final visitorsStream = _firestore
          .collection('visitors')
          .where('communityId', isEqualTo: communityId)
          .where('hostUserId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots();

      final complaintsStream = _firestore
          .collection('complaints')
          .where('communityId', isEqualTo: communityId)
          .where('flatId', isEqualTo: flatId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots();

      // Listen to all streams
      await for (final _ in bookingsStream) {
        try {
          final bookings = await bookingsStream.first;
          final visitors = await visitorsStream.first;
          final complaints = await complaintsStream.first;

          final activities = <ActivityItem>[];

          for (final doc in bookings.docs) {
            activities.add(ActivityItem.fromBooking(doc.data(), doc.id));
          }

          for (final doc in visitors.docs) {
            activities.add(ActivityItem.fromVisitor(doc.data(), doc.id));
          }

          for (final doc in complaints.docs) {
            activities.add(ActivityItem.fromComplaint(doc.data(), doc.id));
          }

          activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final recentActivities = activities.take(limit).toList();

          print('✅ Stream update: ${recentActivities.length} activities');

          yield RecentActivityResult.success(
            message: 'Recent activities updated',
            activities: recentActivities,
          );
        } catch (e) {
          print('⚠️  Stream error: $e');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Stream error: $e');
      print('   Stack trace: $stackTrace');
      yield RecentActivityResult.failure(
        message: 'Stream error: $e',
        errorCode: 'STREAM_ERROR',
      );
    }
  }
}
