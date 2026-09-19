/// Tenant and authorization fields shared by resident and admin profiles.
class TenantProfile {
  final String userId;
  final String communityId;
  final String role;
  final bool isActive;
  final String status;
  final String approvalStatus;
  final List<String> authorizedCommunityIds;
  final String? residentType;
  final String? declaredResidentType;
  final bool identityVerified;
  final String identityVerificationStatus;

  const TenantProfile({
    required this.userId,
    required this.communityId,
    required this.role,
    required this.isActive,
    this.status = 'active',
    this.approvalStatus = 'approved',
    this.authorizedCommunityIds = const [],
    this.residentType,
    this.declaredResidentType,
    this.identityVerified = false,
    this.identityVerificationStatus = 'verification_required',
  });

  factory TenantProfile.fromMap(String userId, Map<String, dynamic> data) {
    return TenantProfile(
      userId: userId,
      communityId: data['communityId'] as String? ?? '',
      role: data['role'] as String? ?? '',
      isActive: data['isActive'] == true,
      status: data['status'] is String
          ? (data['status'] as String).trim().toLowerCase()
          : 'active',
      approvalStatus:
          data['approvalStatus'] as String? ??
          (data['isActive'] == true ? 'approved' : 'blocked'),
      authorizedCommunityIds: List<String>.from(
        data['authorizedCommunityIds'] as List? ?? const [],
      ),
      residentType: _residentType(data),
      declaredResidentType: _type(data['declaredResidentType']),
      identityVerified: data['identityVerified'] == true,
      identityVerificationStatus: _verificationStatus(data),
    );
  }

  bool get isAdmin => role == 'admin' || role == 'superAdmin';

  bool canAccessCommunity(String id) =>
      communityId == id || (isAdmin && authorizedCommunityIds.contains(id));

  static String? _type(Object? value) {
    final type = value is String ? value.trim().toLowerCase() : '';
    return type == 'owner' || type == 'tenant' ? type : null;
  }

  static String? _residentType(Map<String, dynamic> data) {
    final rawResidentType = data['residentType'] is String
        ? (data['residentType'] as String).trim()
        : '';
    final rawOwnershipType = data['ownershipType'] is String
        ? (data['ownershipType'] as String).trim()
        : '';
    final residentType = _type(data['residentType']);
    final ownershipType = _type(data['ownershipType']);
    if ((rawResidentType.isNotEmpty && residentType == null) ||
        (rawOwnershipType.isNotEmpty && ownershipType == null)) {
      return null;
    }
    if (residentType != null &&
        ownershipType != null &&
        residentType != ownershipType) {
      return null;
    }
    return residentType ?? ownershipType;
  }

  static String _verificationStatus(Map<String, dynamic> data) {
    final value = data['identityVerificationStatus'];
    final status = value is String ? value.trim().toLowerCase() : '';
    if (const {
      'verification_required',
      'pending',
      'verified',
      'rejected',
      'not_required',
    }.contains(status)) {
      return status;
    }
    return data['identityVerified'] == true
        ? 'verified'
        : 'verification_required';
  }
}
