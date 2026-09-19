// lib/src/services/flat_access_control_service.dart
// Flat Access Control Service - Manages access based on flat assignment

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Access Control Result
enum FlatAccessState { granted, unauthenticated, denied, error }

class AccessControlResult {
  final FlatAccessState state;
  final String? flatId;
  final String? buildingId;
  final String? message;
  final Map<String, dynamic>? userData;

  const AccessControlResult({
    required this.state,
    this.flatId,
    this.buildingId,
    this.message,
    this.userData,
  });

  bool get hasAccess => state == FlatAccessState.granted;

  bool get isUnauthenticated => state == FlatAccessState.unauthenticated;

  factory AccessControlResult.granted({
    required String flatId,
    required String buildingId,
    required Map<String, dynamic> userData,
  }) {
    return AccessControlResult(
      state: FlatAccessState.granted,
      flatId: flatId,
      buildingId: buildingId,
      userData: userData,
    );
  }

  factory AccessControlResult.unauthenticated() {
    return const AccessControlResult(
      state: FlatAccessState.unauthenticated,
      message: 'Please log in to continue',
    );
  }

  factory AccessControlResult.denied({required String message}) {
    return AccessControlResult(state: FlatAccessState.denied, message: message);
  }

  factory AccessControlResult.error({required String message}) {
    return AccessControlResult(state: FlatAccessState.error, message: message);
  }
}

/// Flat Access Control Service
/// Validates user flat assignment and controls access to features
class FlatAccessControlService {
  // Singleton pattern
  static final FlatAccessControlService instance =
      FlatAccessControlService._internal();
  factory FlatAccessControlService() => instance;
  FlatAccessControlService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Cache
  AccessControlResult? _cachedResult;
  String? _cachedUserId;

  /// Check if user has flat access
  /// Returns AccessControlResult with access status and user data
  Future<AccessControlResult> checkFlatAccess({
    bool forceRefresh = false,
    String? approvedUserId,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return AccessControlResult.unauthenticated();
      }
      if (approvedUserId != null && approvedUserId != firebaseUser.uid) {
        return AccessControlResult.error(
          message: 'The authenticated resident changed during access checks.',
        );
      }
      final userId = firebaseUser.uid;

      // Return cached result if available and not forcing refresh
      if (!forceRefresh && _cachedUserId == userId && _cachedResult != null) {
        return _cachedResult!;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return AccessControlResult.error(
          message: 'The approved resident profile is no longer available.',
        );
      }

      final result = evaluateApprovedProfile(userDoc.data()!);

      // Cache the result
      _cachedResult = result;
      _cachedUserId = userId;

      return result;
    } catch (e, stackTrace) {
      debugPrint('Flat access check failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return AccessControlResult.error(
        message: 'Error checking access. Please try again.',
      );
    }
  }

  /// Stream flat access status (real-time updates)
  Stream<AccessControlResult> streamFlatAccess() async* {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      yield AccessControlResult.unauthenticated();
      return;
    }
    final userId = firebaseUser.uid;
    try {
      yield* _firestore.collection('users').doc(userId).snapshots().map((
        snapshot,
      ) {
        try {
          if (!snapshot.exists) {
            return AccessControlResult.error(
              message: 'The approved resident profile is no longer available.',
            );
          }

          final userData = snapshot.data();
          if (userData == null) {
            return AccessControlResult.error(
              message: 'The approved resident profile could not be read.',
            );
          }

          final result = evaluateApprovedProfile(userData);

          // Update cache
          _cachedResult = result;
          _cachedUserId = userId;

          return result;
        } catch (e) {
          return AccessControlResult.error(
            message: 'Error processing user data. Please try again.',
          );
        }
      });
    } catch (e) {
      yield AccessControlResult.error(
        message: 'Error checking access. Please try again.',
      );
    }
  }

  @visibleForTesting
  static AccessControlResult evaluateApprovedProfile(
    Map<String, dynamic> userData,
  ) {
    if (userData['role'] != 'resident') {
      return AccessControlResult.denied(
        message: 'This app is available to resident accounts only.',
      );
    }
    if (userData['approvalStatus'] != 'approved') {
      return AccessControlResult.denied(
        message: 'Your resident registration is not currently approved.',
      );
    }
    if (userData['isActive'] != true || userData['status'] != 'active') {
      return AccessControlResult.denied(
        message:
            'Your resident account is temporarily deactivated. Contact your community administrator.',
      );
    }
    if (userData['occupancyStatus'] != 'current') {
      return AccessControlResult.denied(
        message: 'Your resident occupancy is not currently active.',
      );
    }
    final flatId = userData['flatId']?.toString().trim();
    if (flatId == null || flatId.isEmpty) {
      return AccessControlResult.denied(
        message:
            'Your account is not yet assigned to a flat. Please contact admin.',
      );
    }
    final buildingId = userData['buildingId']?.toString().trim() ?? '';
    if (buildingId.isEmpty) {
      return AccessControlResult.denied(
        message:
            'Your account is not assigned to a building. Please contact admin.',
      );
    }
    return AccessControlResult.granted(
      flatId: flatId,
      buildingId: buildingId,
      userData: userData,
    );
  }

  /// Clear cached access result
  void clearCache() {
    _cachedResult = null;
    _cachedUserId = null;
  }

  /// Get cached flat ID (if available)
  String? getCachedFlatId() {
    return _cachedResult?.flatId;
  }

  /// Get cached building ID (if available)
  String? getCachedBuildingId() {
    return _cachedResult?.buildingId;
  }

  /// Check if user has access (cached)
  bool hasAccessCached() {
    return _cachedResult?.hasAccess ?? false;
  }
}
