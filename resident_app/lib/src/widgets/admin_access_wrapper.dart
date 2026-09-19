// lib/src/widgets/admin_access_wrapper.dart
// Admin Access Wrapper - Protects admin screens from non-admin access

import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import '../screens/access_blocked_screen.dart';

class AdminAccessWrapper extends StatelessWidget {
  final Widget child;
  final String screenName;

  const AdminAccessWrapper({
    super.key,
    required this.child,
    this.screenName = 'Admin Screen',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAdminAccess(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error checking admin access',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user has admin access
        final hasAccess = snapshot.data ?? false;

        if (!hasAccess) {
          return AccessBlockedScreen(
            title: 'Admin Access Required',
            message: 'You do not have permission to access this screen.',
            details: 'Only building administrators can access $screenName.',
            icon: Icons.admin_panel_settings,
          );
        }

        // User has admin access - show the screen
        return child;
      },
    );
  }

  /// Check if current user is admin
  Future<bool> _checkAdminAccess() async {
    try {
      print('🔐 AdminAccessWrapper: Checking admin access...');
      
      final userDataService = UserDataService.instance;
      final isAdmin = await userDataService.isAdmin();
      
      if (isAdmin) {
        print('✅ AdminAccessWrapper: User is admin - access granted');
      } else {
        print('❌ AdminAccessWrapper: User is not admin - access denied');
      }
      
      return isAdmin;
    } catch (e) {
      print('❌ AdminAccessWrapper: Error checking admin access: $e');
      rethrow;
    }
  }
}
