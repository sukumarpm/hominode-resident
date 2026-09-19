// lib/src/widgets/adaptive_card.dart
// Theme-aware card widget

import 'package:flutter/material.dart';
import '../theme/theme_helpers.dart';

/// Adaptive card that automatically adjusts to theme
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool elevated;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        border: Border.all(
          color: AdaptiveColors.border(context),
        ),
        boxShadow: elevated ? AdaptiveShadow.card(context) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          child: widget,
        ),
      );
    }

    return widget;
  }
}
