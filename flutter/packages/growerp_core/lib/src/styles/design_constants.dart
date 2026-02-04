/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

/// Design system constants for GrowERP.
/// These tokens ensure consistency across all UI components.
library;

import 'package:flutter/material.dart';

// =============================================================================
// Spacing Constants
// =============================================================================

/// Spacing tokens for consistent layout
class GrowerpSpacing {
  GrowerpSpacing._();

  /// 4px - Tight spacing for compact elements
  static const double xs = 4.0;

  /// 8px - Component internal spacing
  static const double sm = 8.0;

  /// 16px - Standard spacing between components
  static const double md = 16.0;

  /// 24px - Section spacing
  static const double lg = 24.0;

  /// 32px - Large section spacing
  static const double xl = 32.0;

  /// 48px - Extra large spacing
  static const double xxl = 48.0;
}

// =============================================================================
// Border Radius Constants
// =============================================================================

/// Border radius tokens for consistent corner styling
class GrowerpRadius {
  GrowerpRadius._();

  /// 8px - Small radius for chips, small buttons
  static const double sm = 8.0;

  /// 12px - Medium radius for cards, inputs
  static const double md = 12.0;

  /// 16px - Large radius for dialogs, navigation
  static const double lg = 16.0;

  /// 20px - Extra large radius for major containers
  static const double xl = 20.0;

  /// BorderRadius shortcuts
  static BorderRadius get smallAll => BorderRadius.circular(sm);
  static BorderRadius get mediumAll => BorderRadius.circular(md);
  static BorderRadius get largeAll => BorderRadius.circular(lg);
  static BorderRadius get extraLargeAll => BorderRadius.circular(xl);
}

// =============================================================================
// Animation Duration Constants
// =============================================================================

/// Animation duration tokens for consistent motion
class GrowerpDuration {
  GrowerpDuration._();

  /// 100ms - Micro interactions (hover, focus)
  static const Duration fast = Duration(milliseconds: 100);

  /// 200ms - Standard transitions
  static const Duration normal = Duration(milliseconds: 200);

  /// 300ms - Medium transitions
  static const Duration medium = Duration(milliseconds: 300);

  /// 500ms - Slow transitions (page changes)
  static const Duration slow = Duration(milliseconds: 500);

  /// 600ms - Entrance animations
  static const Duration entrance = Duration(milliseconds: 600);
}

// =============================================================================
// Elevation/Shadow Constants
// =============================================================================

/// Shadow configurations for elevation effects
class GrowerpShadow {
  GrowerpShadow._();

  /// Subtle card shadow
  static List<BoxShadow> card(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Hover state shadow
  static List<BoxShadow> hover(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];

  /// Elevated surface shadow
  static List<BoxShadow> elevated(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];
}

// =============================================================================
// Typography Extensions
// =============================================================================

/// Typography scale extensions for TextTheme
extension GrowerpTypography on TextTheme {
  /// Large display text - 28px, bold
  TextStyle get displayLarge =>
      headlineLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 28) ??
      const TextStyle(fontWeight: FontWeight.w700, fontSize: 28);

  /// Section heading - 22px, semibold
  TextStyle get sectionHeading =>
      headlineMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 22) ??
      const TextStyle(fontWeight: FontWeight.w600, fontSize: 22);

  /// Card title - 18px, semibold
  TextStyle get cardTitle =>
      titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18) ??
      const TextStyle(fontWeight: FontWeight.w600, fontSize: 18);

  /// Body text - 15px, regular
  TextStyle get bodyDefault =>
      bodyLarge?.copyWith(fontWeight: FontWeight.w400, fontSize: 15) ??
      const TextStyle(fontWeight: FontWeight.w400, fontSize: 15);

  /// Caption text - 13px, regular
  TextStyle get captionText =>
      bodySmall?.copyWith(fontWeight: FontWeight.w400, fontSize: 13) ??
      const TextStyle(fontWeight: FontWeight.w400, fontSize: 13);

  /// Label text - 13px, medium weight
  TextStyle get labelDefault =>
      labelLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 13) ??
      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13);
}
