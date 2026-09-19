// lib/src/screens/access_blocked_screen.dart
// Access Blocked Screen - Shown when user has no flat assignment

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
import '../services/resident_auth_routing.dart';
import '../services/tenant_resolution_service.dart';

class AccessBlockedScreen extends StatelessWidget {
  final String message;

  const AccessBlockedScreen({
    super.key,
    this.message =
        'Your account is not yet assigned to a flat. Please contact admin.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 60.w,
                  color: Colors.orange.shade700,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final tenantResolver = context
                        .read<TenantResolutionService>();

                    final result = await FirebaseAuthService.instance
                        .restoreResidentSession(tenantResolver);

                    if (!context.mounted) return;

                    Navigator.of(context).pushNamedAndRemoveUntil(
                      ResidentAuthRouting.routeFor(result),
                      (route) => false,
                      arguments: result.message,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Refresh Status',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Contact Admin Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add contact admin functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please contact your building administrator',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: Text(
                    'Contact Admin',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E4778),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Sign out
                    await FirebaseAuthService.instance.signOut(
                      context.read<TenantResolutionService>(),
                    );

                    if (context.mounted) {
                      // Navigate to login
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Info text
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Your account needs to be linked to a flat by an administrator before you can access the app features.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
