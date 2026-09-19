import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hominode_notifications/hominode_notifications.dart';
import 'package:hominode_sos/hominode_sos.dart';

import '../screens/notifications_screen.dart';

final residentNotificationNavigatorKey = GlobalKey<NavigatorState>();

class ResidentNotificationRouter {
  const ResidentNotificationRouter._();

  static Future<NavigatorState?> _waitForNavigator() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final navigator = residentNotificationNavigatorKey.currentState;
      if (navigator != null) return navigator;

      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    return residentNotificationNavigatorKey.currentState;
  }

  static Future<void> handle(HominodeNotificationPayload payload) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server)),
      firestore
          .collection('notifications')
          .doc(payload.entityId)
          .get(const GetOptions(source: Source.server)),
    ]);
    final profile = results[0].data();
    final notification = results[1].data();
    final canonicalCommunityId = profile?['communityId'];

    final authorized =
        profile != null &&
        profile['uid'] == user.uid &&
        profile['role'] == 'resident' &&
        profile['approvalStatus'] == 'approved' &&
        profile['isActive'] == true &&
        (profile['status'] == null || profile['status'] == 'active') &&
        canonicalCommunityId == payload.communityId &&
        notification != null &&
        notification['recipientId'] == user.uid &&
        notification['communityId'] == canonicalCommunityId &&
        notification['audience'] == 'resident' &&
        notification['role'] == 'resident' &&
        notification['appId'] == 'resident';
    if (!authorized) return;
    final navigator = await _waitForNavigator();
    if (navigator == null) {
      throw StateError('Resident navigation is not ready.');
    }
    final sosId = sosAlertIdFromNotification(notification);
    if (sosId != null) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => SosDetailPage(
            communityId: payload.communityId,
            alertId: sosId,
            responder: false,
          ),
        ),
      );
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }
}
