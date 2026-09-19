import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hominode_notifications/hominode_notifications.dart';
import 'package:resident_app/src/services/resident_registration_service.dart';

import '../models/tenant_profile.dart';
import 'flat_access_control_service.dart';
import 'resident_access_policy.dart';
import 'tenant_resolution_service.dart';

enum ResidentAuthState {
  approved,
  flatAssignmentRequired,
  identityVerificationRequired,
  registrationRequired,
  pendingApproval,
  rejected,
  blocked,
  failed,
  inactive,
}

class AuthResult {
  final bool success;
  final String? message;
  final String? errorCode;
  final User? user;
  final TenantContext? tenant;
  final ResidentAuthState state;

  const AuthResult({
    required this.success,
    this.message,
    this.errorCode,
    this.user,
    this.tenant,
    this.state = ResidentAuthState.failed,
  });

  factory AuthResult.success({
    String? message,
    User? user,
    TenantContext? tenant,
    ResidentAuthState state = ResidentAuthState.approved,
  }) => AuthResult(
    success: true,
    message: message ?? 'Operation successful',
    user: user,
    tenant: tenant,
    state: state,
  );

  factory AuthResult.failure({required String message, String? errorCode}) =>
      AuthResult(
        success: false,
        message: message,
        errorCode: errorCode,
        state: ResidentAuthState.failed,
      );

  bool get canEnterApp => success && state == ResidentAuthState.approved;
}

abstract interface class ResidentPhoneAuthGateway {
  String formatPhoneNumber(String phone);
  bool validatePhoneNumber(String phone);
  Future<void> sendOtp({
    required String phoneNumber,
    required ValueChanged<String> onCodeSent,
    required ValueChanged<AuthResult> onError,
    bool forceResend = false,
  });
}

/// Resident authentication gateway. Firebase Phone Auth is the only supported
/// sign-in mechanism; profile and tenant authorization are checked afterwards.
class FirebaseAuthService implements ResidentPhoneAuthGateway {
  static final FirebaseAuthService instance = FirebaseAuthService._internal();

  factory FirebaseAuthService() => instance;

  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  // Store automatic verification credential temporarily.
  // IMPORTANT: Do not sign in from verificationCompleted.
  PhoneAuthCredential? _pendingAutoCredential;

  User? get currentUser => _auth.currentUser;

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required ValueChanged<String> onCodeSent,
    required ValueChanged<AuthResult> onError,
    bool forceResend = false,
  }) async {
    // Clear credentials from any previous OTP attempt.
    _pendingAutoCredential = null;

    if (kDebugMode) {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResend ? _resendToken : null,

      verificationCompleted: (credential) {
        // IMPORTANT:
        // Firebase may automatically verify the phone.
        // DO NOT call signInWithCredential or resolve resident access here.
        _pendingAutoCredential = credential;

        debugPrint(
          '[PhoneAuth] Automatic verification credential received. '
          'Waiting for OTP verification flow to complete.',
        );
      },

      verificationFailed: (error) {
        debugPrint(
          '[PhoneAuth] verificationFailed '
          'code=${error.code} '
          'message=${error.message}',
        );

        onError(
          AuthResult.failure(
            message: _messageForCode(error.code),
            errorCode: error.code,
          ),
        );
      },

      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;

        debugPrint('[PhoneAuth] OTP sent. verificationId received.');

        onCodeSent(verificationId);
      },

      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;

        debugPrint('[PhoneAuth] Auto retrieval timeout.');
      },
    );
  }

  Future<AuthResult> verifyOtp({
    required String smsCode,
    required TenantResolutionService tenantResolver,
    String? verificationId,
  }) async {
    try {
      PhoneAuthCredential credential;

      // Android may already have supplied a valid credential.
      if (_pendingAutoCredential != null) {
        credential = _pendingAutoCredential!;
        debugPrint('[PhoneAuth] Using automatic verification credential.');
      } else {
        final id = verificationId ?? _verificationId;

        if (id == null || id.isEmpty) {
          return AuthResult.failure(
            message: 'Verification session expired. Request a new OTP.',
            errorCode: 'missing-verification-id',
          );
        }

        credential = PhoneAuthProvider.credential(
          verificationId: id,
          smsCode: smsCode,
        );
      }

      // Clear it before authentication so it cannot be reused.
      _pendingAutoCredential = null;

      // THIS is now the only point where phone sign-in occurs.
      return await _completePhoneSignIn(credential, tenantResolver);
    } catch (e, stackTrace) {
      debugPrint('[PhoneAuth] verifyOtp error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return AuthResult.failure(
        message: 'Unable to verify this phone number. Please try again.',
      );
    }
  }

  Future<AuthResult> restoreResidentSession(
    TenantResolutionService tenantResolver,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthResult.failure(message: 'No authenticated session.');
    }
    return _resolveResident(user, tenantResolver);
  }

  Future<AuthResult> _completePhoneSignIn(
    PhoneAuthCredential credential,
    TenantResolutionService tenantResolver,
  ) async {
    try {
      final user = (await _auth.signInWithCredential(credential)).user;
      if (user == null || user.phoneNumber == null) {
        await _rejectSession(tenantResolver);
        return AuthResult.failure(message: 'Phone authentication failed.');
      }
      return _resolveResident(user, tenantResolver);
    } on FirebaseAuthException catch (error) {
      await _rejectSession(tenantResolver);
      return AuthResult.failure(
        message: _messageForCode(error.code),
        errorCode: error.code,
      );
    } catch (_) {
      await _rejectSession(tenantResolver);
      return AuthResult.failure(
        message: 'Unable to verify this phone number. Please try again.',
      );
    }
  }

  Future<AuthResult> _resolveResident(
    User user,
    TenantResolutionService tenantResolver,
  ) async {
    try {
      var profile = await tenantResolver.loadAuthenticatedProfile();

      if (profile == null) {
        final claimed = await ResidentRegistrationService()
            .claimImportedOnboarding();

        if (claimed) {
          // The callable has now created users/{uid}. Clear any cached tenant/profile
          // state before reading the newly created canonical resident profile.
          tenantResolver.clear();
          profile = await tenantResolver.loadAuthenticatedProfile();
        }

        if (profile == null) {
          return AuthResult.success(
            message:
                'No resident account is linked to this phone number. Please contact your Community Admin.',
            user: user,
            state: ResidentAuthState.registrationRequired,
          );
        }
      }

      // 2. Validate Role
      if (profile.role != 'resident') {
        await _rejectSession(tenantResolver);
        return AuthResult.success(
          message: 'This phone number is not registered as a Resident account.',
          user: user,
          state: ResidentAuthState.blocked,
        );
      }

      // 3. Validate Status
      switch (profile.approvalStatus) {
        case 'pending':
          if (!ResidentAccessPolicy.identitySatisfied(profile) &&
              profile.identityVerificationStatus != 'not_required') {
            final message = switch (profile.identityVerificationStatus) {
              'pending' =>
                'Your identity proof is awaiting administrator verification.',
              'rejected' =>
                'Your identity proof was rejected. Upload a new proof to continue.',
              _ => 'Upload identity proof to continue verification.',
            };

            return AuthResult.success(
              message: message,
              user: user,
              state: ResidentAuthState.identityVerificationRequired,
            );
          }

          return AuthResult.success(
            message: 'Your registration is awaiting admin approval.',
            user: user,
            state: ResidentAuthState.pendingApproval,
          );
        case 'rejected':
          return AuthResult.success(
            message:
                'Your resident registration was rejected. Contact your community administrator.',
            user: user,
            state: ResidentAuthState.rejected,
          );
        case 'blocked':
          return AuthResult.success(
            message:
                'Your resident account is blocked. Contact your community administrator.',
            user: user,
            state: ResidentAuthState.blocked,
          );
      }
      if (!profile.isActive) {
        return AuthResult.success(
          message:
              'Your Resident account is not active. Please contact your Community Admin.',
          user: user,
          state: ResidentAuthState.inactive,
        );
      }
      // Tenants always require verified identity before operational
      // community access. Route them to the verification workflow before
      // attempting protected community reads.
      final residentType = profile.residentType ?? profile.declaredResidentType;

      if (residentType == 'tenant' &&
          !ResidentAccessPolicy.identitySatisfied(profile)) {
        return AuthResult.success(
          message: profile.identityVerificationStatus == 'rejected'
              ? 'Your identity proof was rejected. Upload a new proof to continue.'
              : 'Identity verification is required before resident access is enabled.',
          user: user,
          state: ResidentAuthState.identityVerificationRequired,
        );
      }

      final community = await tenantResolver.loadAssignedCommunity(profile);
      final operationalAccess = ResidentAccessPolicy.evaluate(
        profile,
        community,
      );
      if (operationalAccess ==
          ResidentOperationalAccess.identityVerificationRequired) {
        return AuthResult.success(
          message: profile.identityVerificationStatus == 'rejected'
              ? 'Your identity proof was rejected. Upload a new proof to continue.'
              : 'Identity verification is required before resident access is enabled.',
          user: user,
          state: ResidentAuthState.identityVerificationRequired,
        );
      }
      if (operationalAccess ==
          ResidentOperationalAccess.residentTypeAmbiguous) {
        return AuthResult.success(
          message:
              'Your owner or tenant classification is missing. Contact your community administrator.',
          user: user,
          state: ResidentAuthState.blocked,
        );
      }

      // 4. Resolve Tenant Context
      final tenant = await tenantResolver.resolve();
      final roleFailure = validateResidentProfile(tenant.profile);
      if (roleFailure != null) {
        await _rejectSession(tenantResolver);
        return AuthResult.failure(
          message: roleFailure,
          errorCode: 'wrong-role',
        );
      }

      final flatAccess = await FlatAccessControlService.instance
          .checkFlatAccess(forceRefresh: true, approvedUserId: user.uid);
      if (flatAccess.state == FlatAccessState.denied) {
        return AuthResult.success(
          message: flatAccess.message,
          user: user,
          tenant: tenant,
          state: ResidentAuthState.flatAssignmentRequired,
        );
      }
      if (flatAccess.state != FlatAccessState.granted) {
        return AuthResult.failure(
          message: flatAccess.message ?? 'Unable to verify flat access.',
          errorCode: 'flat-access-check-failed',
        );
      }

      return AuthResult.success(
        message: 'Phone verified successfully.',
        user: user,
        tenant: tenant,
        state: ResidentAuthState.approved,
      );
    } on TenantResolutionException catch (error) {
      await _rejectSession(tenantResolver);
      return AuthResult.success(
        message: error.message,
        user: user,
        state: ResidentAuthState.blocked,
      );
    } catch (e) {
      debugPrint('[PhoneAuth] Unexpected error during resident resolution: $e');

      tenantResolver.clear();
      FlatAccessControlService.instance.clearCache();

      return AuthResult.failure(
        message: 'Unable to load your resident profile. Please try again.',
        errorCode: 'resident-profile-read-failed',
      );
    }
  }

  @visibleForTesting
  static String? validateResidentProfile(TenantProfile profile) {
    if (!profile.isActive) {
      return 'Your Resident account is not active. Please contact your Community Admin.';
    }
    if (profile.communityId.isEmpty) {
      return 'This account is not assigned to a community.';
    }
    if (profile.role != 'resident') {
      return 'This phone number is not registered as a Resident account.';
    }
    return null;
  }

  Future<AuthResult> signOut([TenantResolutionService? tenantResolver]) async {
    debugPrint('🚨 FirebaseAuthService.signOut CALLED');
    debugPrintStack();

    try {
      await HominodePushNotifications.instance.deactivateForLogout();
      await _auth.signOut();
      tenantResolver?.clear();
      FlatAccessControlService.instance.clearCache();

      return AuthResult.success(message: 'Signed out successfully.');
    } catch (_) {
      return AuthResult.failure(
        message: 'Failed to sign out. Please try again.',
      );
    }
  }

  Future<void> _rejectSession(TenantResolutionService tenantResolver) async {
    debugPrint('🚨 _rejectSession CALLED');
    debugPrintStack();

    tenantResolver.clear();
    FlatAccessControlService.instance.clearCache();

    await HominodePushNotifications.instance.deactivateForLogout();
    await _auth.signOut();
  }

  @override
  bool validatePhoneNumber(String phone) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(formatPhoneNumber(phone));

  @override
  String formatPhoneNumber(String phone) =>
      phone.trim().replaceAll(RegExp(r'[\s()-]'), '');

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check the OTP and try again.';
      case 'session-expired':
      case 'code-expired':
      case 'missing-verification-id':
        return 'This verification session has expired. Please request a new OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'quota-exceeded':
        return 'OTP service is temporarily unavailable. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled. Please contact support.';
      default:
        return 'Phone authentication failed. Please try again.';
    }
  }
}
