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

import 'package:flutter/material.dart';
import 'package:growerp_core/src/styles/color_schemes.dart';

/// Semantic status types for the StatusChip widget.
enum StatusType {
  /// Success state - completed, paid, shipped, approved
  success,

  /// Warning state - pending, attention needed, processing
  warning,

  /// Danger state - overdue, cancelled, failed, rejected
  danger,

  /// Info state - informational, in-progress, draft
  info,

  /// Neutral state - uses theme's default colors
  neutral,
}

/// A semantic status chip widget for displaying status indicators.
///
/// Uses the semantic color system defined in color_schemes.dart to provide
/// consistent status presentation across the app.
///
/// Usage:
/// ```dart
/// StatusChip(
///   label: 'Completed',
///   type: StatusType.success,
/// )
///
/// StatusChip(
///   label: 'Pending',
///   type: StatusType.warning,
///   icon: Icons.schedule,
/// )
/// ```
class StatusChip extends StatelessWidget {
  /// The text label to display in the chip
  final String label;

  /// The semantic type determining the chip's color
  final StatusType type;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Whether to use a filled or outlined style
  final bool filled;

  /// Optional custom size (small, medium, large)
  final StatusChipSize size;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.filled = true,
    this.size = StatusChipSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _getColors(colorScheme);
    final dimensions = _getDimensions();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalPadding,
        vertical: dimensions.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: filled ? colors.background : Colors.transparent,
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        border: Border.all(color: colors.border, width: filled ? 0 : 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dimensions.iconSize, color: colors.foreground),
            SizedBox(width: dimensions.iconSpacing),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dimensions.fontSize,
              fontWeight: FontWeight.w500,
              color: colors.foreground,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusChipColors _getColors(ColorScheme colorScheme) {
    switch (type) {
      case StatusType.success:
        return _StatusChipColors(
          background: colorScheme.success.withValues(alpha: filled ? 0.15 : 0),
          foreground: colorScheme.success,
          border: colorScheme.success,
        );
      case StatusType.warning:
        return _StatusChipColors(
          background: colorScheme.warning.withValues(alpha: filled ? 0.15 : 0),
          foreground: colorScheme.warning,
          border: colorScheme.warning,
        );
      case StatusType.danger:
        return _StatusChipColors(
          background: colorScheme.danger.withValues(alpha: filled ? 0.15 : 0),
          foreground: colorScheme.danger,
          border: colorScheme.danger,
        );
      case StatusType.info:
        return _StatusChipColors(
          background: colorScheme.info.withValues(alpha: filled ? 0.15 : 0),
          foreground: colorScheme.info,
          border: colorScheme.info,
        );
      case StatusType.neutral:
        return _StatusChipColors(
          background: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          foreground: colorScheme.onSurfaceVariant,
          border: colorScheme.outline,
        );
    }
  }

  _StatusChipDimensions _getDimensions() {
    switch (size) {
      case StatusChipSize.small:
        return const _StatusChipDimensions(
          horizontalPadding: 6,
          verticalPadding: 2,
          fontSize: 11,
          iconSize: 12,
          iconSpacing: 3,
          borderRadius: 6,
        );
      case StatusChipSize.medium:
        return const _StatusChipDimensions(
          horizontalPadding: 10,
          verticalPadding: 4,
          fontSize: 13,
          iconSize: 14,
          iconSpacing: 4,
          borderRadius: 8,
        );
      case StatusChipSize.large:
        return const _StatusChipDimensions(
          horizontalPadding: 14,
          verticalPadding: 6,
          fontSize: 15,
          iconSize: 18,
          iconSpacing: 6,
          borderRadius: 10,
        );
    }
  }
}

/// Size variants for StatusChip
enum StatusChipSize { small, medium, large }

class _StatusChipColors {
  final Color background;
  final Color foreground;
  final Color border;

  const _StatusChipColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

class _StatusChipDimensions {
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;
  final double borderRadius;

  const _StatusChipDimensions({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
    required this.borderRadius,
  });
}

/// Helper function to get StatusType from common status strings
StatusType getStatusTypeFromString(String status) {
  final lowerStatus = status.toLowerCase();

  // Success states
  if (lowerStatus.contains('complete') ||
      lowerStatus.contains('paid') ||
      lowerStatus.contains('shipped') ||
      lowerStatus.contains('approved') ||
      lowerStatus.contains('active') ||
      lowerStatus.contains('confirmed')) {
    return StatusType.success;
  }

  // Warning states
  if (lowerStatus.contains('pending') ||
      lowerStatus.contains('processing') ||
      lowerStatus.contains('waiting') ||
      lowerStatus.contains('hold') ||
      lowerStatus.contains('partial')) {
    return StatusType.warning;
  }

  // Danger states
  if (lowerStatus.contains('overdue') ||
      lowerStatus.contains('cancel') ||
      lowerStatus.contains('fail') ||
      lowerStatus.contains('reject') ||
      lowerStatus.contains('error') ||
      lowerStatus.contains('expired')) {
    return StatusType.danger;
  }

  // Info states
  if (lowerStatus.contains('draft') ||
      lowerStatus.contains('progress') ||
      lowerStatus.contains('new') ||
      lowerStatus.contains('open') ||
      lowerStatus.contains('created')) {
    return StatusType.info;
  }

  return StatusType.neutral;
}
