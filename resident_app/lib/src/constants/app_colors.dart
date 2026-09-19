// lib/src/constants/app_colors.dart
// Centralized color tokens for the entire app
// Use these constants instead of hardcoded Color values

import 'package:flutter/material.dart';

class AppColors {
  // ============================================================================
  // PRIMARY COLORS
  // ============================================================================

  /// Primary brand blue - used for buttons, links, active states
  static const Color primary = Color(0xFF0E4778);

  /// Darker shade of primary - used for gradients, hover states
  static const Color primaryDark = Color(0xFF061C4C);

  /// Lighter shade of primary - used for backgrounds, subtle highlights
  static const Color primaryLight = Color(0xFF3AA6C8);

  /// Very light primary - used for icon backgrounds
  static const Color primaryLightest = Color(0xFFEAF1FF);

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  /// Main app background color
  static const Color background = Color(0xFFF7F7F7);

  /// Card/surface background color
  static const Color surface = Color(0xFFFFFFFF);

  /// Search bar background
  static const Color searchBar = Color(0xFFF1F1F1);

  /// Input field background
  static const Color inputBackground = Color(0xFFFFFFFF);

  /// Disabled background
  static const Color disabled = Color(0xFFF3F4F6);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text color - headings, important text
  static const Color textPrimary = Color(0xFF111111);

  /// Secondary text color - body text, descriptions
  static const Color textSecondary = Color(0xFF6B7280);

  /// Tertiary text color - captions, timestamps
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Disabled text color
  static const Color textDisabled = Color(0xFFD1D5DB);

  /// Text on primary color backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================================================
  // BORDER & DIVIDER COLORS
  // ============================================================================

  /// Standard border color for cards, inputs
  static const Color border = Color(0xFFE5E7EB);

  /// Divider lines between sections
  static const Color divider = Color(0xFFECEFF3);

  /// Focus border color for inputs
  static const Color borderFocus = primary;

  /// Error border color
  static const Color borderError = Color(0xFFEF4444);

  // ============================================================================
  // STATUS COLORS
  // ============================================================================

  /// Success color - completed, approved, positive actions
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);

  /// Warning color - pending, attention needed
  static const Color warning = Color(0xFFF97316);
  static const Color warningLight = Color(0xFFFFF3E8);
  static const Color warningDark = Color(0xFFEA580C);

  /// Error color - failed, rejected, destructive actions
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  /// Info color - informational messages
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // ============================================================================
  // SEMANTIC COLORS (Icon Backgrounds)
  // ============================================================================

  /// Blue icon background
  static const Color iconBgBlue = Color(0xFFEAF1FF);
  static const Color iconBlue = Color(0xFF3B82F6);

  /// Green icon background
  static const Color iconBgGreen = Color(0xFFE8FDEB);
  static const Color iconGreen = Color(0xFF10B981);

  /// Purple icon background
  static const Color iconBgPurple = Color(0xFFEDE9FF);
  static const Color iconPurple = Color(0xFF8B5CF6);

  /// Orange icon background
  static const Color iconBgOrange = Color(0xFFFFF3E8);
  static const Color iconOrange = Color(0xFFF97316);

  /// Red icon background
  static const Color iconBgRed = Color(0xFFFEE2E2);
  static const Color iconRed = Color(0xFFEF4444);

  /// Yellow icon background
  static const Color iconBgYellow = Color(0xFFFEF3C7);
  static const Color iconYellow = Color(0xFFFDB022);

  /// Gray icon background
  static const Color iconBgGray = Color(0xFFF3F4F6);
  static const Color iconGray = Color(0xFF6B7280);

  // ============================================================================
  // SPECIAL PURPOSE COLORS
  // ============================================================================

  /// Unread badge/notification indicator
  static const Color unreadBadge = Color(0xFFE53935);

  /// Online status dot
  static const Color onlineDot = Color(0xFF10B981);

  /// Offline status dot
  static const Color offlineDot = Color(0xFF9CA3AF);

  /// Overlay/modal background dim
  static const Color overlay = Color(0x80000000); // 50% black

  /// Shimmer loading effect base
  static const Color shimmerBase = Color(0xFFE5E7EB);

  /// Shimmer loading effect highlight
  static const Color shimmerHighlight = Color(0xFFF9FAFB);

  // ============================================================================
  // GRADIENT DEFINITIONS
  // ============================================================================

  /// Primary gradient for headers
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  /// Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successDark],
  );

  /// Error gradient (for emergency features)
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [error, errorDark],
  );

  // ============================================================================
  // SHADOW COLORS
  // ============================================================================

  /// Standard card shadow
  static Color get cardShadow => Colors.black.withOpacity(0.04);

  /// Elevated card shadow
  static Color get cardShadowElevated => Colors.black.withOpacity(0.08);

  /// Button shadow
  static Color get buttonShadow => primary.withOpacity(0.3);

  /// Modal shadow
  static Color get modalShadow => Colors.black.withOpacity(0.5);
}
