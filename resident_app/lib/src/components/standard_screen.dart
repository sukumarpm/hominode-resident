import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'standard_header.dart';

/// Standard Screen Wrapper - Ensures consistent status bar and header across ALL screens
///
/// Features:
/// - Transparent status bar
/// - Light status bar icons (white)
/// - Gradient extends into status bar
/// - Standard header with consistent styling
/// - Scrollable content area
///
/// Usage:
/// ```dart
/// StandardScreen(
///   title: 'Screen Title',
///   body: YourContentWidget(),
/// )
/// ```
class StandardScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBackPressed;
  final List<Widget>? headerActions;
  final bool showBackButton;
  final bool isScrollable;
  final EdgeInsets? padding;

  const StandardScreen({
    super.key,
    required this.title,
    required this.body,
    this.onBackPressed,
    this.headerActions,
    this.showBackButton = true,
    this.isScrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent to show gradient
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Column(
          children: [
            // Standard Header (gradient extends into status bar)
            StandardHeader(
              title: title,
              onBackPressed: onBackPressed,
              actions: headerActions,
              showBackButton: showBackButton,
            ),

            // Content Area
            Expanded(
              child: isScrollable
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: padding ?? EdgeInsets.all(16.w),
                      child: body,
                    )
                  : Padding(
                      padding: padding ?? EdgeInsets.all(16.w),
                      child: body,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard Screen with Search
class StandardScreenWithSearch extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchPressed;
  final bool showBackButton;
  final bool isScrollable;
  final EdgeInsets? padding;

  const StandardScreenWithSearch({
    super.key,
    required this.title,
    required this.body,
    this.onBackPressed,
    this.onSearchPressed,
    this.showBackButton = true,
    this.isScrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: title,
      body: body,
      onBackPressed: onBackPressed,
      showBackButton: showBackButton,
      isScrollable: isScrollable,
      padding: padding,
      headerActions: [
        if (onSearchPressed != null)
          GestureDetector(
            onTap: onSearchPressed,
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.search, color: Colors.white, size: 24.w),
            ),
          ),
      ],
    );
  }
}

/// Standard Screen with Menu
class StandardScreenWithMenu extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;
  final bool isScrollable;
  final EdgeInsets? padding;

  const StandardScreenWithMenu({
    super.key,
    required this.title,
    required this.body,
    this.onBackPressed,
    this.onMenuPressed,
    this.showBackButton = true,
    this.isScrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: title,
      body: body,
      onBackPressed: onBackPressed,
      showBackButton: showBackButton,
      isScrollable: isScrollable,
      padding: padding,
      headerActions: [
        if (onMenuPressed != null)
          GestureDetector(
            onTap: onMenuPressed,
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.more_vert, color: Colors.white, size: 24.w),
            ),
          ),
      ],
    );
  }
}
