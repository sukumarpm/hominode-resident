import 'package:flutter/material.dart';

import 'firebase_auth_service.dart';

enum ResidentAuthenticationIntent { login, register }

class ResidentAuthRouting {
  const ResidentAuthRouting._();

  /// Resolves the destination route name based on the authentication result.
  static String routeFor(AuthResult result) {
    if (!result.success && result.state == ResidentAuthState.failed) {
      return '/login';
    }

    switch (result.state) {
      case ResidentAuthState.approved:
        return '/home';

      case ResidentAuthState.registrationRequired:
        return '/resident-registration';

      case ResidentAuthState.pendingApproval:
        return '/awaiting-approval';

      case ResidentAuthState.identityVerificationRequired:
        return '/resident-identity-verification';

      case ResidentAuthState.inactive:
        return '/resident-access-blocked';

      case ResidentAuthState.rejected:
      case ResidentAuthState.blocked:
      case ResidentAuthState.flatAssignmentRequired:
        return '/resident-access-blocked';

      case ResidentAuthState.failed:
        return '/login';
    }
  }

  /// Login never turns an unknown phone into a registration. Register uses
  /// the same OTP verification but may continue to the existing registration
  /// screen when no canonical resident profile exists.
  static AuthResult resultForIntent(
    AuthResult result,
    ResidentAuthenticationIntent intent,
  ) {
    if (intent == ResidentAuthenticationIntent.login &&
        result.state == ResidentAuthState.registrationRequired) {
      return AuthResult.failure(
        message:
            'No resident account is linked to this phone number. Please contact your Community Admin.',
        errorCode: 'resident-registration-required',
      );
    }
    return result;
  }

  /// Executes safe root navigation, clearing the stack and passing AuthResult data.
  static void navigateToResult(BuildContext context, AuthResult result) {
    final routeName = routeFor(result);

    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: result.message,
    );
  }
}
