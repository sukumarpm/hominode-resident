import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/community_model.dart';
import '../models/resident_registration_model.dart';

class ResidentRegistrationException implements Exception {
  final String message;
  final String? code;
  const ResidentRegistrationException(this.message, {this.code});
  @override
  String toString() => message;
}

class ResidentRegistrationService {
  ResidentRegistrationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static String normalizeInviteCode(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_-]'), '');

  static Map<String, dynamic> callablePayload(
    ResidentRegistrationModel registration,
  ) => {
    'inviteCode': normalizeInviteCode(registration.communityInviteCode),
    'fullName': registration.name.trim(),
    'email': registration.email?.trim(),
    'buildingReference': registration.buildingReference.trim(),
    'unitReference': registration.unitReference.trim(),
    'residentType': registration.residentType.trim().toLowerCase(),
  };

  static const importedOnboardingPayload = <String, dynamic>{
    'claimImportedOnboarding': true,
  };

  /// Claims a trusted Admin-created onboarding for the currently OTP-verified
  /// phone. Returns false when this phone has no pending onboarding.
  Future<bool> claimImportedOnboarding() async {
    final user = _auth.currentUser;
    if (user == null || user.phoneNumber == null) {
      throw const ResidentRegistrationException(
        'Your verified phone session is no longer valid.',
      );
    }
    try {
      final response = await _functions
          .httpsCallable('registerResident')
          .call(importedOnboardingPayload);
      final data = response.data;
      return data is Map && data['communityId'] is String;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found') return false;
      throw ResidentRegistrationException(
        error.message ?? 'Imported registration could not be completed.',
        code: error.code,
      );
    }
  }

  Future<CommunityInvite> resolveInvite(String rawCode) async {
    final code = normalizeInviteCode(rawCode);
    if (code.length < 4) {
      throw const ResidentRegistrationException(
        'Enter a valid community code.',
      );
    }
    if (_auth.currentUser == null) {
      throw const ResidentRegistrationException(
        'Verify your phone number first.',
      );
    }

    final invite = await _firestore
        .collection('communityInvites')
        .doc(code)
        .get();
    final inviteData = invite.data();
    if (!invite.exists ||
        inviteData == null ||
        inviteData['isActive'] != true) {
      throw const ResidentRegistrationException(
        'Community code is invalid or inactive.',
      );
    }
    final expiresAt = inviteData['expiresAt'] as Timestamp?;
    if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
      throw const ResidentRegistrationException('Community code has expired.');
    }
    final maxUses = inviteData['maxUses'] as int?;
    final useCount = inviteData['useCount'] as int? ?? 0;
    if (maxUses != null && useCount >= maxUses) {
      throw const ResidentRegistrationException(
        'Community code has reached its usage limit.',
      );
    }
    final communityId = inviteData['communityId'] as String? ?? '';
    if (communityId.isEmpty) {
      throw const ResidentRegistrationException(
        'Community code is not configured correctly.',
      );
    }

    final communityDoc = await _firestore
        .collection('communities')
        .doc(communityId)
        .get();
    if (!communityDoc.exists) {
      throw const ResidentRegistrationException(
        'Community could not be found.',
      );
    }
    final community = CommunityModel.fromFirestore(communityDoc);
    if (!community.isActive) {
      throw const ResidentRegistrationException(
        'This community is not accepting registrations.',
      );
    }
    return CommunityInvite(
      code: code,
      communityId: community.id,
      communityName: community.name,
      logoUrl: community.logoUrl,
    );
  }

  Future<String> register(ResidentRegistrationModel registration) async {
    final user = _auth.currentUser;
    if (user == null ||
        user.uid != registration.uid ||
        user.phoneNumber == null) {
      throw const ResidentRegistrationException(
        'Your verified phone session is no longer valid.',
      );
    }
    if (user.phoneNumber != registration.phoneNumber) {
      throw const ResidentRegistrationException(
        'Verified phone number does not match.',
      );
    }

    try {
      final response = await _functions
          .httpsCallable('registerResident')
          .call(callablePayload(registration));
      final data = response.data;
      return data is Map && data['status'] is String
          ? data['status'] as String
          : 'pending';
    } on FirebaseFunctionsException catch (error) {
      throw ResidentRegistrationException(
        error.message ?? 'Registration could not be submitted.',
        code: error.code,
      );
    }
  }
}
