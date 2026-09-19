import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/community_feature_flags.dart';
import '../models/community_model.dart';
import '../models/tenant_profile.dart';

enum TenantResolutionFailure {
  unauthenticated,
  profileMissing,
  profileInactive,
  profileNotApproved,
  wrongRole,
  communityMissing,
  communityInactive,
}

class TenantResolutionException implements Exception {
  final TenantResolutionFailure reason;
  final String message;

  const TenantResolutionException(this.reason, this.message);

  @override
  String toString() => message;
}

class TenantContext {
  final TenantProfile profile;
  final CommunityModel community;

  const TenantContext({required this.profile, required this.community});

  String get communityId => community.id;
  String get name => community.name;
  String get slug => community.slug;
  String get websitePath => community.websitePath;
  String get databaseId => community.databaseId;
  String? get logoUrl => community.logoUrl;
  String get brandName => community.brandName;
  String? get primaryColor => community.primaryColor;
  bool get isActive => community.isActive;
  CommunityFeatureFlags get featureFlags => community.features;
}

/// Single source of truth for resolving the signed-in user's tenant.
class TenantResolutionService extends ChangeNotifier {
  TenantResolutionService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  TenantContext? _current;

  TenantContext? get current => _current;
  CommunityModel? get community => _current?.community;
  String? get communityId => _current?.communityId;

  Future<TenantProfile?> loadAuthenticatedProfile() async {
    final user = _auth.currentUser;

    debugPrint(
      '[TenantProfile] authUid=${user?.uid} '
      'phone=${user?.phoneNumber} '
      'project=${_firestore.app.options.projectId}',
    );

    if (user == null) return null;

    final snapshot = await _firestore.collection('users').doc(user.uid).get();

    debugPrint(
      '[TenantProfile] users/${user.uid} '
      'exists=${snapshot.exists} '
      'data=${snapshot.data()}',
    );

    final data = snapshot.data();
    return data == null ? null : TenantProfile.fromMap(user.uid, data);
  }

  Future<TenantContext> resolve() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const TenantResolutionException(
        TenantResolutionFailure.unauthenticated,
        'A Firebase-authenticated user is required.',
      );
    }

    final profileDocument = await _loadProfile(user.uid);
    if (profileDocument == null) {
      throw const TenantResolutionException(
        TenantResolutionFailure.profileMissing,
        'No resident profile exists for this account.',
      );
    }

    final profile = requireApprovedResident(user.uid, profileDocument);

    final communityDocument = await _firestore
        .collection('communities')
        .doc(profile.communityId)
        .get();
    if (!communityDocument.exists) {
      throw const TenantResolutionException(
        TenantResolutionFailure.communityMissing,
        'The assigned community does not exist.',
      );
    }

    final community = requireActiveCommunity(
      profile,
      CommunityModel.fromFirestore(communityDocument),
    );

    _current = TenantContext(profile: profile, community: community);
    notifyListeners();
    return _current!;
  }

  Future<CommunityModel> loadAssignedCommunity(TenantProfile profile) async {
    if (profile.communityId.trim().isEmpty) {
      throw const TenantResolutionException(
        TenantResolutionFailure.profileMissing,
        'This account is not assigned to a community.',
      );
    }
    final document = await _firestore
        .collection('communities')
        .doc(profile.communityId)
        .get();
    if (!document.exists) {
      throw const TenantResolutionException(
        TenantResolutionFailure.communityMissing,
        'The assigned community does not exist.',
      );
    }
    return requireActiveCommunity(
      profile,
      CommunityModel.fromFirestore(document),
    );
  }

  Future<Map<String, dynamic>?> _loadProfile(String uid) async {
    final user = await _firestore.collection('users').doc(uid).get();
    return user.data();
  }

  @visibleForTesting
  static TenantProfile requireApprovedResident(
    String uid,
    Map<String, dynamic> data,
  ) {
    final profile = TenantProfile.fromMap(uid, data);
    if (profile.role != 'resident') {
      throw const TenantResolutionException(
        TenantResolutionFailure.wrongRole,
        'This app is available to resident accounts only.',
      );
    }
    if (profile.approvalStatus != 'approved') {
      throw const TenantResolutionException(
        TenantResolutionFailure.profileNotApproved,
        'This resident account is not approved.',
      );
    }
    if (!profile.isActive) {
      throw const TenantResolutionException(
        TenantResolutionFailure.profileInactive,
        'This account is inactive.',
      );
    }
    if (profile.communityId.trim().isEmpty) {
      throw const TenantResolutionException(
        TenantResolutionFailure.profileMissing,
        'This account is not assigned to a community.',
      );
    }
    return profile;
  }

  @visibleForTesting
  static CommunityModel requireActiveCommunity(
    TenantProfile profile,
    CommunityModel? community,
  ) {
    if (community == null || community.id != profile.communityId) {
      throw const TenantResolutionException(
        TenantResolutionFailure.communityMissing,
        'The assigned community does not exist.',
      );
    }
    if (!community.isActive) {
      throw const TenantResolutionException(
        TenantResolutionFailure.communityInactive,
        'The assigned community is inactive.',
      );
    }
    return community;
  }

  void clear() {
    _current = null;
    notifyListeners();
  }
}
