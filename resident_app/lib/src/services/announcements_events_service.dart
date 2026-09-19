// lib/src/services/announcements_events_service.dart
// Service for fetching tenant-scoped announcements and events from Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/announcement_model.dart';
import '../models/event_model.dart';

class AnnouncementsEventsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Query<Map<String, dynamic>> _visibleEventsQuery(String communityId) {
    return _firestore
        .collection('events')
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: 'published');
  }

  /// Get current resident's community ID
  Future<String?> _getCurrentCommunityId() async {
    final user = _auth.currentUser;

    if (user == null) {
      print('❌ AnnouncementsEventsService: User not authenticated');
      return null;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      print('❌ AnnouncementsEventsService: User document not found');
      return null;
    }

    final data = userDoc.data();
    final communityId = data?['communityId'] as String?;

    if (communityId == null || communityId.isEmpty) {
      print(
        '❌ AnnouncementsEventsService: communityId missing for ${user.uid}',
      );
      return null;
    }

    return communityId;
  }

  /// Stream active announcements for current resident's community
  Stream<List<AnnouncementModel>> streamAnnouncements() async* {
    try {
      final communityId = await _getCurrentCommunityId();

      if (communityId == null) {
        yield [];
        return;
      }

      print('📢 Streaming announcements for community: $communityId');

      yield* _firestore
          .collection('announcements')
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) {
            final announcements = snapshot.docs
                .map((doc) => AnnouncementModel.fromFirestore(doc))
                .toList();

            announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            print('✅ Streamed ${announcements.length} announcements');

            return announcements;
          });
    } catch (e) {
      print('❌ Error starting announcements stream: $e');
      rethrow;
    }
  }

  /// Stream published events for current resident's community
  Stream<List<EventModel>> streamEvents() async* {
    try {
      final communityId = await _getCurrentCommunityId();

      if (communityId == null) {
        yield [];
        return;
      }

      print('📅 Streaming events for community: $communityId');

      yield* _visibleEventsQuery(communityId).snapshots().map((snapshot) {
        final events = snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList();

        events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('✅ Streamed ${events.length} events');

        return events;
      });
    } catch (e) {
      print('❌ Error starting events stream: $e');
      rethrow;
    }
  }

  /// Count events visible under the same tenant and status rules as streamEvents.
  Future<int> getVisibleEventsCount(String communityId) async {
    if (communityId.isEmpty) return 0;

    final snapshot = await _visibleEventsQuery(communityId).count().get();
    return snapshot.count ?? 0;
  }
}
