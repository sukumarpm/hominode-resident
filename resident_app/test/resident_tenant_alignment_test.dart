import 'package:flutter_test/flutter_test.dart';
import 'package:resident_app/src/models/community_model.dart';
import 'package:resident_app/src/services/tenant_resolution_service.dart';

void main() {
  Map<String, dynamic> residentProfile({
    String communityId = 'community-a',
    String role = 'resident',
    String approvalStatus = 'approved',
    bool isActive = true,
  }) => {
    'communityId': communityId,
    'role': role,
    'approvalStatus': approvalStatus,
    'isActive': isActive,
  };

  test('legacy tenant metadata uses safe aligned defaults', () {
    final community = CommunityModel.fromMap('community-a', {
      'name': ' Green Valley ',
      'isActive': true,
    });

    expect(community.id, 'community-a');
    expect(community.slug, 'green-valley');
    expect(community.websitePath, 'green-valley');
    expect(community.databaseId, '(default)');
    expect(community.brandName, 'Green Valley');
    expect(community.logoUrl, isNull);
    expect(community.primaryColor, isNull);
  });

  test('complete tenant metadata is exposed through resident context', () {
    final profile = TenantResolutionService.requireApprovedResident(
      'resident-1',
      residentProfile(),
    );
    final community = CommunityModel.fromMap('community-a', {
      'name': 'Green Valley',
      'slug': 'green-valley',
      'websitePath': 'green',
      'databaseId': 'tenant-green',
      'brandName': 'Green Living',
      'logoUrl': 'https://example.test/logo.png',
      'primaryColor': '#123456',
      'isActive': true,
    });
    final context = TenantContext(profile: profile, community: community);

    expect(context.communityId, 'community-a');
    expect(context.name, 'Green Valley');
    expect(context.websitePath, 'green');
    expect(context.databaseId, 'tenant-green');
    expect(context.brandName, 'Green Living');
    expect(context.isActive, isTrue);
  });

  test('resident tenant is fixed to the profile community', () {
    final profile = TenantResolutionService.requireApprovedResident(
      'resident-1',
      residentProfile(),
    );
    final requestedOtherCommunity = CommunityModel.fromMap('community-b', {
      'name': 'Other Community',
      'isActive': true,
    });

    expect(
      () => TenantResolutionService.requireActiveCommunity(
        profile,
        requestedOtherCommunity,
      ),
      throwsA(
        isA<TenantResolutionException>().having(
          (error) => error.reason,
          'reason',
          TenantResolutionFailure.communityMissing,
        ),
      ),
    );
  });

  test('missing and inactive communities fail closed', () {
    final profile = TenantResolutionService.requireApprovedResident(
      'resident-1',
      residentProfile(),
    );
    expect(
      () => TenantResolutionService.requireActiveCommunity(profile, null),
      throwsA(isA<TenantResolutionException>()),
    );

    final inactive = CommunityModel.fromMap('community-a', {
      'name': 'Green Valley',
      'isActive': false,
    });
    expect(
      () => TenantResolutionService.requireActiveCommunity(profile, inactive),
      throwsA(
        isA<TenantResolutionException>().having(
          (error) => error.reason,
          'reason',
          TenantResolutionFailure.communityInactive,
        ),
      ),
    );
  });

  test('resident role, approval, and active state are required', () {
    expect(
      () => TenantResolutionService.requireApprovedResident(
        'resident-1',
        residentProfile(role: 'admin'),
      ),
      throwsA(isA<TenantResolutionException>()),
    );
    expect(
      () => TenantResolutionService.requireApprovedResident(
        'resident-1',
        residentProfile(approvalStatus: 'pending'),
      ),
      throwsA(isA<TenantResolutionException>()),
    );
    expect(
      () => TenantResolutionService.requireApprovedResident(
        'resident-1',
        residentProfile(isActive: false),
      ),
      throwsA(isA<TenantResolutionException>()),
    );
  });
}
