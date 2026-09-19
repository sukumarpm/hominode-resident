// lib/src/services/notice_firestore_service.dart
// Notice/Notification Firestore Service - Fetch notices from Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notice_model.dart';

/// Notice Firestore Service
class NoticeFirestoreService {
  // Singleton pattern
  static final NoticeFirestoreService instance =
      NoticeFirestoreService._internal();
  factory NoticeFirestoreService() => instance;
  NoticeFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  // Collection name
  static const String noticesCollection = 'notices';

  // ============================================================================
  // GET NOTICES
  // ============================================================================

  /// Get all active notices for current user
  /// Filters by:
  /// - isActive: true OR status: "published"
  /// - Not expired
  /// - targetFlats is empty (all flats) OR contains user's flat
  Future<List<NoticeModel>> getNotices() async {
    try {
      print('🔵 Fetching notices from Firestore...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return [];
      }

      final scope = await _loadResidentScope(user.uid);
      if (scope == null) {
        print('❌ Canonical resident community/flat scope is unavailable');
        return [];
      }
      final userFlatId = scope.flatId;
      print('🔵 User flat ID: $userFlatId');

      print('🔵 Resolving tenant- and flat-scoped notice IDs...');

      // Ensure Firebase Auth has a valid ID token before invoking
      // the authenticated callable.
      final token = await user.getIdToken();

      if (token == null || token.isEmpty) {
        print('❌ Firebase Auth token is unavailable');
        return [];
      }

      print('🔐 NOTICE AUTH UID: ${user.uid}');
      print('🔐 NOTICE AUTH TOKEN AVAILABLE: true');

      final result = await _functions
          .httpsCallable('getResidentNoticeIds')
          .call();
      final response = Map<String, dynamic>.from(result.data as Map);
      if (response['communityId'] != scope.communityId ||
          response['flatId'] != scope.flatId) {
        print('❌ Trusted notice scope does not match the current profile');
        return [];
      }
      final noticeIds = (response['noticeIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      final noticeDocuments = await Future.wait(
        noticeIds.map(
          (noticeId) =>
              _firestore.collection(noticesCollection).doc(noticeId).get(),
        ),
      );

      print(
        '🔵 Found ${noticeDocuments.length} authorized notices in Firestore',
      );

      final now = DateTime.now();
      final notices = <NoticeModel>[];

      for (var doc in noticeDocuments) {
        try {
          final data = doc.data();
          if (!doc.exists || data == null) continue;
          if (data['communityId'] != scope.communityId) continue;
          print('📄 Processing notice: ${doc.id}');
          print('   Raw data keys: ${data.keys.toList()}');
          print('   status: ${data['status']}');
          print('   isActive: ${data['isActive']}');

          // Check if notice is active/published
          final isActive =
              data['isActive'] == true || data['status'] == 'published';
          if (!isActive) {
            print(
              '⏭️ Skipping inactive notice: ${doc.id} (status=${data['status']}, isActive=${data['isActive']})',
            );
            continue;
          }

          // Parse dates - handle both field name variations
          DateTime? publishDate;
          DateTime? expiryDate;

          // publishDate / publishedAt
          try {
            if (data['publishDate'] != null) {
              publishDate = (data['publishDate'] as Timestamp).toDate();
              print('   publishDate: $publishDate');
            } else if (data['publishedAt'] != null) {
              publishDate = (data['publishedAt'] as Timestamp).toDate();
              print('   publishedAt: $publishDate');
            } else if (data['createdAt'] != null) {
              publishDate = (data['createdAt'] as Timestamp).toDate();
              print('   using createdAt: $publishDate');
            } else {
              publishDate = DateTime.now();
              print('   using now: $publishDate');
            }
          } catch (e) {
            print('   ⚠️ Error parsing publishDate: $e');
            publishDate = DateTime.now();
          }

          // expiryDate / expiresAt
          try {
            if (data['expiryDate'] != null) {
              expiryDate = (data['expiryDate'] as Timestamp).toDate();
              print('   expiryDate: $expiryDate');
            } else if (data['expiresAt'] != null) {
              expiryDate = (data['expiresAt'] as Timestamp).toDate();
              print('   expiresAt: $expiryDate');
            }
          } catch (e) {
            print('   ⚠️ Error parsing expiryDate: $e');
          }

          // Check if expired
          if (expiryDate != null && now.isAfter(expiryDate)) {
            print(
              '⏭️ Skipping expired notice: ${data['title'] ?? doc.id} (expired: $expiryDate)',
            );
            continue;
          }

          // Create notice model with flexible field mapping
          // Handle both 'type' and 'category' field names
          final categoryValue =
              (data['type'] as String?) ??
              (data['category'] as String?) ??
              'general';
          print('   category/type: $categoryValue');

          final targetFlats =
              (data['targetFlats'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [];

          // Check if notice is for this user's flat
          // If targetFlats is empty, show to all users
          // If targetFlats has values, only show if user's flat is in the list
          if (targetFlats.isNotEmpty && !targetFlats.contains(userFlatId)) {
            print('⏭️ Skipping notice not targeted to user flat: $userFlatId');
            continue;
          }

          final notice = NoticeModel(
            id: doc.id,
            title: data['title'] as String? ?? 'Notice',
            content: data['content'] as String? ?? '',
            category: categoryValue,
            priority: data['priority'] as String? ?? 'medium',
            authorId: data['authorId'] as String? ?? '',
            authorName: data['authorName'] as String? ?? 'Admin',
            attachments:
                (data['attachments'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
            publishDate: publishDate,
            expiryDate: expiryDate,
            isActive: isActive,
            targetFlats: targetFlats,
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );

          // Add notice if it passes all filters
          notices.add(notice);
          print('✅ Added notice: ${notice.title}');
        } catch (e, stackTrace) {
          print('❌ Error parsing notice ${doc.id}: $e');
          print('   Stack trace: $stackTrace');
        }
      }

      print('✅ Returning ${notices.length} notices');

      // Sort by publish date (newest first)
      notices.sort((a, b) => b.publishDate.compareTo(a.publishDate));

      return notices;
    } catch (e, stackTrace) {
      print('❌ Error fetching notices: $e');
      print('   Stack trace: $stackTrace');
      return [];
    }
  }

  /// Stream notices (real-time updates)
  Stream<List<NoticeModel>> streamNotices() {
    return Stream.fromFuture(getNotices());
  }

  Future<_ResidentNoticeScope?> _loadResidentScope(String uid) async {
    try {
      final profile = await _firestore.collection('users').doc(uid).get();
      final data = profile.data();
      if (!profile.exists || data == null) return null;

      final communityId = data['communityId']?.toString().trim() ?? '';
      final flatId = data['flatId']?.toString().trim() ?? '';
      if (communityId.isEmpty || flatId.isEmpty) return null;

      return _ResidentNoticeScope(communityId: communityId, flatId: flatId);
    } catch (e) {
      print('⚠️ Could not resolve canonical resident notice scope: $e');
      return null;
    }
  }

  // ============================================================================
  // MARK AS READ (Optional - for future use)
  // ============================================================================

  /// Mark notice as read for current user
  /// This creates a read receipt in a subcollection
  Future<void> markAsRead(String noticeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(noticesCollection)
          .doc(noticeId)
          .collection('readBy')
          .doc(user.uid)
          .set({'readAt': FieldValue.serverTimestamp(), 'userId': user.uid});

      print('✅ Marked notice $noticeId as read');
    } catch (e) {
      print('❌ Error marking notice as read: $e');
    }
  }

  /// Check if notice has been read by current user
  Future<bool> isRead(String noticeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection(noticesCollection)
          .doc(noticeId)
          .collection('readBy')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking read status: $e');
      return false;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final notices = await getNotices();
      int unreadCount = 0;

      for (var notice in notices) {
        final isRead = await this.isRead(notice.id);
        if (!isRead) unreadCount++;
      }

      return unreadCount;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }
}

class _ResidentNoticeScope {
  const _ResidentNoticeScope({required this.communityId, required this.flatId});

  final String communityId;
  final String flatId;
}
