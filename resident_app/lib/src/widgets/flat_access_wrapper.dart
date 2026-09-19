import 'package:flutter/material.dart';

import '../screens/access_blocked_screen.dart';
import '../screens/simple_login_screen.dart';
import '../services/flat_access_control_service.dart';

/// Wraps child widgets to enforce live flat and resident lifecycle access.
class FlatAccessWrapper extends StatelessWidget {
  final Widget child;

  const FlatAccessWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AccessControlResult>(
      stream: FlatAccessControlService.instance.streamFlatAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFF06182B),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'lib/assets/images/resident_login_background.png',
                  fit: BoxFit.cover,
                ),
                Container(
                  color: const Color(0xFF06182B).withValues(alpha: 0.18),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'lib/assets/Resident_New.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF31D6E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final result = snapshot.data;
        if (result == null || result.state == FlatAccessState.error) {
          return Scaffold(
            body: Center(
              child: Text(result?.message ?? 'Unable to check flat access.'),
            ),
          );
        }
        if (result.state == FlatAccessState.unauthenticated) {
          return const SimpleLoginScreen();
        }
        if (result.state == FlatAccessState.denied) {
          return AccessBlockedScreen(
            message:
                result.message ??
                'Your account is not yet assigned to a flat. Please contact admin.',
          );
        }
        return child;
      },
    );
  }
}
