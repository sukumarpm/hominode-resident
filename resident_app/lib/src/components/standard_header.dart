import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_sizes.dart';
import '../constants/app_colors.dart';

/// Standard Header Component - Use across ALL screens for consistency
///
/// Features:
/// - Blue gradient background (#2563EB → #1E40AF)
/// - Gradient extends into status bar area
/// - Back button (optional)
/// - Title text (white, 18px, Semibold)
/// - Action buttons (optional)
/// - Rounded bottom corners (18px)
/// - Safe area handling
/// - Consistent padding and sizing
///
/// Usage:
/// ```dart
/// StandardHeader(
///   title: 'Screen Title',
///   onBackPressed: () => Navigator.pop(context),
/// )
/// ```
class StandardHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final double? titleSize;

  const StandardHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    // Get status bar height
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final shouldShowBackButton = showBackButton && Navigator.canPop(context);

    return Container(
      // Extend gradient into status bar
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: BoxDecoration(
        gradient: backgroundColor == null ? AppColors.primaryGradient : null,
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18.r),
          bottomRight: Radius.circular(18.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          shouldShowBackButton ? 8 : 16,
          AppSizes.headerPaddingVertical,
          16.w,
          AppSizes.headerPaddingBottom,
        ),
        child: Row(
          children: [
            // Back button
            if (shouldShowBackButton)
              Semantics(
                label: 'Back button',
                button: true,
                child: GestureDetector(
                  onTap: onBackPressed ?? () => Navigator.maybePop(context),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20.w,
                    ),
                  ),
                ),
              ),

            if (shouldShowBackButton) SizedBox(width: 4.w),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleSize ?? AppTextSizes.screenTitle,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Action buttons
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

/// Standard Header with Search - For screens with search functionality
class StandardHeaderWithSearch extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchPressed;
  final bool showBackButton;

  const StandardHeaderWithSearch({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onSearchPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return StandardHeader(
      title: title,
      onBackPressed: onBackPressed,
      showBackButton: showBackButton,
      actions: [
        if (onSearchPressed != null)
          Semantics(
            label: 'Search button',
            button: true,
            child: GestureDetector(
              onTap: onSearchPressed,
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(Icons.search, color: Colors.white, size: 24.w),
              ),
            ),
          ),
      ],
    );
  }
}

/// Standard Header with Menu - For screens with menu/options
class StandardHeaderWithMenu extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;

  const StandardHeaderWithMenu({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onMenuPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return StandardHeader(
      title: title,
      onBackPressed: onBackPressed,
      showBackButton: showBackButton,
      actions: [
        if (onMenuPressed != null)
          Semantics(
            label: 'Menu button',
            button: true,
            child: GestureDetector(
              onTap: onMenuPressed,
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(Icons.more_vert, color: Colors.white, size: 24.w),
              ),
            ),
          ),
      ],
    );
  }
}

/// Standard Header with Notification - For screens with notifications
class StandardHeaderWithNotification extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNotificationPressed;
  final bool showBackButton;
  final bool hasUnread;

  const StandardHeaderWithNotification({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onNotificationPressed,
    this.showBackButton = true,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return StandardHeader(
      title: title,
      onBackPressed: onBackPressed,
      showBackButton: showBackButton,
      actions: [
        if (onNotificationPressed != null)
          Semantics(
            label: 'Notifications button',
            button: true,
            child: GestureDetector(
              onTap: onNotificationPressed,
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24.w,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
