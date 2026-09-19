import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityInvite {
  final String code;
  final String communityId;
  final String communityName;
  final String? logoUrl;

  const CommunityInvite({
    required this.code,
    required this.communityId,
    required this.communityName,
    this.logoUrl,
  });
}

class ResidentRegistrationModel {
  final String uid;
  final String phoneNumber;
  final String name;
  final String communityId;
  final String communityInviteCode;
  final String buildingReference;
  final String unitReference;
  final String? email;
  final String residentType;

  const ResidentRegistrationModel({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.communityId,
    required this.communityInviteCode,
    required this.buildingReference,
    required this.unitReference,
    this.email,
    required this.residentType,
  });

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'phoneNumber': phoneNumber,
    'phone': phoneNumber,
    'name': name,
    'fullName': name,
    'communityId': communityId,
    'communityInviteCode': communityInviteCode,
    'role': 'resident',
    'isActive': false,
    'approvalStatus': 'pending',
    'declaredResidentType': residentType,
    'identityVerified': false,
    'identityVerificationStatus': 'verification_required',
    'buildingReference': buildingReference,
    'unitReference': unitReference,
    'buildingId': null,
    'unitId': null,
    'flatId': null,
    'email': email,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
