// lib/src/theme/theme_helpers.dart
// Helper functions and extensions for theme access (Light mode only)

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Extension on BuildContext for easy theme access
extension ThemeExtension on BuildContext {
  /// Get current theme
  ThemeData get theme => Theme.of(this);

  /// Get theme colors
  ColorScheme get colors => theme.colorScheme;

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;
}

/// Gradient helper for light theme
class AdaptiveGradient {
  /// Get gradient for headers
  static LinearGradient header(BuildContext context) {
    return AppColors.primaryGradient;
  }

  /// Get gradient for cards
  static LinearGradient card(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFFAFBFC)],
    );
  }
}

/// Color helper for light theme
class AdaptiveColors {
  /// Get background color
  static Color background(BuildContext context) {
    return const Color(0xFFFAFBFC);
  }

  /// Get surface/card color
  static Color surface(BuildContext context) {
    return Colors.white;
  }

  /// Get elevated surface color
  static Color surfaceElevated(BuildContext context) {
    return Colors.white;
  }

  /// Get primary text color
  static Color textPrimary(BuildContext context) {
    return const Color(0xFF0F172A);
  }

  /// Get secondary text color
  static Color textSecondary(BuildContext context) {
    return const Color(0xFF6B7280);
  }

  /// Get muted text color
  static Color textMuted(BuildContext context) {
    return const Color(0xFF9AA0A6);
  }

  /// Get border color
  static Color border(BuildContext context) {
    return const Color(0xFFE5E7EB);
  }

  /// Get divider color
  static Color divider(BuildContext context) {
    return const Color(0xFFECEFF3);
  }

  /// Get icon background color
  static Color iconBackground(BuildContext context) {
    return const Color(0xFFF0F2F5);
  }

  /// Get primary color
  static Color primary(BuildContext context) {
    return AppColors.primary;
  }

  /// Get success color
  static Color success(BuildContext context) {
    return const Color(0xFF22C55E);
  }

  /// Get warning color
  static Color warning(BuildContext context) {
    return const Color(0xFFF59E0B);
  }

  /// Get error color
  static Color error(BuildContext context) {
    return const Color(0xFFEF4444);
  }
}

/// Shadow helper for light theme
class AdaptiveShadow {
  /// Get card shadow
  static List<BoxShadow> card(BuildContext context) {
    return const [
      BoxShadow(color: Color(0x10182840), blurRadius: 10, offset: Offset(0, 2)),
    ];
  }

  /// Get elevated shadow
  static List<BoxShadow> elevated(BuildContext context) {
    return const [
      BoxShadow(color: Color(0x15182840), blurRadius: 15, offset: Offset(0, 4)),
    ];
  }
}

/// Adaptive text styles
class AdaptiveTextStyles {
  /// Get headline style
  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AdaptiveColors.textPrimary(context),
    );
  }

  /// Get title style
  static TextStyle title(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AdaptiveColors.textPrimary(context),
    );
  }

  /// Get subtitle style
  static TextStyle subtitle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AdaptiveColors.textPrimary(context),
    );
  }

  /// Get body style
  static TextStyle body(BuildContext context) {
    return TextStyle(fontSize: 14, color: AdaptiveColors.textPrimary(context));
  }

  /// Get body secondary style
  static TextStyle bodySecondary(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: AdaptiveColors.textSecondary(context),
    );
  }

  /// Get caption style
  static TextStyle caption(BuildContext context) {
    return TextStyle(fontSize: 12, color: AdaptiveColors.textMuted(context));
  }
}
