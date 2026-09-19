import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hominode_notifications/hominode_notifications.dart';

import 'dashboard_screen.dart';
import 'src/screens/visitor_management_screen_new.dart';
import 'maintenance_billing_screen.dart';
import 'events_announcements_screen.dart';
import 'profile_screen.dart';
import 'src/widgets/flat_access_wrapper.dart';
import 'src/constants/app_colors.dart';

/// Main Navigation Screen with Smooth Animated Bottom Navigation Bar
/// Uses IndexedStack to preserve state of all screens while switching tabs
/// Wrapped with FlatAccessWrapper for access control
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  // Inactive color for navigation items
  Color get inactiveColor => const Color(0xFF64748B);

  // All screens - state is preserved with IndexedStack
  List<Widget> get _screens => [
    DashboardScreen(onTabChange: _onTabTapped),
    const VisitorManagementScreenNew(),
    const MaintenanceBillingScreen(),
    const EventsAnnouncementsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animationController.forward();
    unawaited(HominodePushNotifications.instance.activate());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      // Trigger animation on tab change
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlatAccessWrapper(
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildAnimatedBottomNavBar(),
      ),
    );
  }

  /// Animated Bottom Navigation Bar with smooth transitions
  Widget _buildAnimatedBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'home'.tr(),
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'visitors'.tr(),
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'billing'.tr(),
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'events'.tr(),
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'profile'.tr(),
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Individual animated navigation item
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12.r),
        splashColor: AppColors.primaryLight.withAlpha(25),
        highlightColor: AppColors.primaryLight.withAlpha(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon with size and color transition
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isActive ? 6 : 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryLight.withAlpha(25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : inactiveColor,
                  size: isActive ? 24 : 22,
                ),
              ),
              SizedBox(height: 3.h),
              // Animated Label with color and weight transition
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isActive ? const Color(0xFF0E4778) : inactiveColor,
                  fontSize: 10.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
