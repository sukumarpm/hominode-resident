// lib/src/components/app_card.dart
// Standardized card component for consistent UI across the app

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Card size variants
enum AppCardSize {
  small,  // 10px padding
  medium, // 12px padding (default)
  large,  // 16px padding
}

/// Standardized card component with consistent styling
/// 
/// Design Specs:
/// - Background: White (#FFFFFF)
/// - Border: 1px #E5E7EB
/// - Border Radius: 14px
/// - Shadow: rgba(0, 0, 0, 0.04) blur 8px, offset (0, 2)
/// - Padding: 10px/12px/16px based on size
/// 
/// Usage:
/// ```dart
/// AppCard(
///   child: Text('Content'),
/// )
/// 
/// AppCard(
///   size: AppCardSize.large,
///   onTap: () => print('Tapped'),
///   child: Column(children: [...]),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// The widget to display inside the card
  final Widget child;
  
  /// Custom padding (overrides size-based padding)
  final EdgeInsetsGeometry? padding;
  
  /// Tap callback - makes card tappable with ripple effect
  final VoidCallback? onTap;
  
  /// Card size variant (affects padding)
  final AppCardSize size;
  
  /// Custom background color (default: white)
  final Color? backgroundColor;
  
  /// Whether to show border (default: true)
  final bool hasBorder;
  
  /// Whether to show shadow (default: true)
  final bool hasShadow;
  
  /// Custom border radius (default: 14px)
  final double? borderRadius;
  
  /// Custom border color (default: AppColors.border)
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.size = AppCardSize.medium,
    this.backgroundColor,
    this.hasBorder = true,
    this.hasShadow = true,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? _getPadding();
    final effectiveRadius = borderRadius ?? 14.0;
    
    Widget cardContent = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: hasBorder
            ? Border.all(color: borderColor ?? AppColors.border)
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
    
    // If onTap is provided, wrap in InkWell for ripple effect
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: cardContent,
        ),
      );
    }
    
    return cardContent;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppCardSize.small:
        return const EdgeInsets.all(10);
      case AppCardSize.medium:
        return const EdgeInsets.all(12);
      case AppCardSize.large:
        return const EdgeInsets.all(16);
    }
  }
}

/// Elevated card variant with stronger shadow
class AppCardElevated extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final AppCardSize size;

  const AppCardElevated({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.size = AppCardSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadowElevated,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppCard(
        size: size,
        padding: padding,
        onTap: onTap,
        hasShadow: false, // Shadow already applied above
        child: child,
      ),
    );
  }
}

/// Outlined card variant (no fill, just border)
class AppCardOutlined extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final AppCardSize size;
  final Color? borderColor;

  const AppCardOutlined({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.size = AppCardSize.medium,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      size: size,
      padding: padding,
      onTap: onTap,
      backgroundColor: Colors.transparent,
      hasShadow: false,
      borderColor: borderColor,
      child: child,
    );
  }
}
