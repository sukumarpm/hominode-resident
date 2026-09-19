import 'package:flutter_test/flutter_test.dart';
import 'package:resident_app/src/models/community_model.dart';
import 'package:resident_app/src/models/tenant_profile.dart';
import 'package:resident_app/src/services/resident_access_policy.dart';
import 'package:resident_app/src/services/resident_identity_service.dart';

void main() {
  CommunityModel community({
    String id = 'community-a',
    bool ownerRequired = false,
  }) => CommunityModel(
    id: id,
    name: 'Community',
    slug: 'community',
    websitePath: 'community',
    brandName: 'Community',
    isActive: true,
    ownerIdentityVerificationRequired: ownerRequired,
  );

  TenantProfile profile({
    String type = 'owner',
    bool active = true,
    bool verified = false,
    String verificationStatus = 'not_required',
    String approvalStatus = 'approved',
    String communityId = 'community-a',
    String status = 'active',
  }) => TenantProfile(
    userId: 'resident-1',
    communityId: communityId,
    role: 'resident',
    isActive: active,
    status: status,
    approvalStatus: approvalStatus,
    residentType: type,
    identityVerified: verified,
    identityVerificationStatus: verificationStatus,
  );

  test('owner without proof proceeds when owner proof is optional', () {
    expect(
      ResidentAccessPolicy.evaluate(profile(), community()),
      ResidentOperationalAccess.allowed,
    );
  });

  test('tenant required, pending, and rejected states stay restricted', () {
    for (final status in ['verification_required', 'pending', 'rejected']) {
      expect(
        ResidentAccessPolicy.evaluate(
          profile(type: 'tenant', verificationStatus: status),
          community(),
        ),
        ResidentOperationalAccess.identityVerificationRequired,
      );
    }
  });

  test('verified tenant can use resident features', () {
    expect(
      ResidentAccessPolicy.evaluate(
        profile(type: 'tenant', verified: true, verificationStatus: 'verified'),
        community(),
      ),
      ResidentOperationalAccess.allowed,
    );
  });

  test('verified proof cannot be normally re-uploaded', () {
    expect(ResidentIdentityService.canUploadForStatus('verified'), isFalse);
    expect(ResidentIdentityService.canUploadForStatus('pending'), isTrue);
    expect(ResidentIdentityService.canUploadForStatus('rejected'), isTrue);
    expect(
      ResidentIdentityService.canUploadForStatus('verification_required'),
      isTrue,
    );
  });

  test('inactive, pending, and wrong-community profiles fail closed', () {
    expect(
      ResidentAccessPolicy.evaluate(profile(active: false), community()),
      ResidentOperationalAccess.inactive,
    );
    expect(
      ResidentAccessPolicy.evaluate(profile(status: 'inactive'), community()),
      ResidentOperationalAccess.inactive,
    );
    expect(
      ResidentAccessPolicy.evaluate(profile(status: 'moved_out'), community()),
      ResidentOperationalAccess.inactive,
    );
    expect(
      ResidentAccessPolicy.evaluate(
        profile(approvalStatus: 'pending'),
        community(),
      ),
      ResidentOperationalAccess.pendingApproval,
    );
    expect(
      ResidentAccessPolicy.evaluate(
        profile(communityId: 'community-b'),
        community(),
      ),
      ResidentOperationalAccess.wrongCommunity,
    );
  });
}
