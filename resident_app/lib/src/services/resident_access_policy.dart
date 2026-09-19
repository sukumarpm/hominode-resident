import '../models/community_model.dart';
import '../models/tenant_profile.dart';

enum ResidentOperationalAccess {
  allowed,
  pendingApproval,
  inactive,
  wrongCommunity,
  residentTypeAmbiguous,
  identityVerificationRequired,
}

class ResidentAccessPolicy {
  const ResidentAccessPolicy._();

  static bool identityRequired(
    TenantProfile profile,
    CommunityModel community,
  ) =>
      profile.residentType == 'tenant' ||
      (profile.residentType == 'owner' &&
          community.ownerIdentityVerificationRequired);

  static bool identitySatisfied(TenantProfile profile) =>
      profile.identityVerified &&
      profile.identityVerificationStatus == 'verified';

  static ResidentOperationalAccess evaluate(
    TenantProfile profile,
    CommunityModel community,
  ) {
    if (profile.approvalStatus != 'approved') {
      return ResidentOperationalAccess.pendingApproval;
    }
    if (profile.communityId != community.id || !community.isActive) {
      return ResidentOperationalAccess.wrongCommunity;
    }
    if (profile.residentType != 'owner' && profile.residentType != 'tenant') {
      return ResidentOperationalAccess.residentTypeAmbiguous;
    }
    if (identityRequired(profile, community) && !identitySatisfied(profile)) {
      return ResidentOperationalAccess.identityVerificationRequired;
    }
    if (!profile.isActive || profile.status != 'active') {
      return ResidentOperationalAccess.inactive;
    }
    return ResidentOperationalAccess.allowed;
  }
}
