/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

Duration snackBarDuration(Color color, {int? seconds}) {
  if (seconds != null) {
    return Duration(seconds: seconds);
  }
  final isError = color == Colors.red;
  return Duration(milliseconds: isError ? 5000 : 2000);
}

/// Maps the passed color to a theme-appropriate color
Color _resolveSnackBarColor(BuildContext context, Color color) {
  final colorScheme = Theme.of(context).colorScheme;

  // Map hardcoded colors to theme colors
  if (color == Colors.red) {
    return colorScheme.error;
  } else if (color == Colors.green) {
    return colorScheme.primary;
  }
  // Return original color if not a standard success/error color
  return color;
}

SnackBar snackBar(
  BuildContext context,
  Color color,
  String message, {
  int? seconds,
}) {
  final resolvedDuration = snackBarDuration(color, seconds: seconds);
  final resolvedColor = _resolveSnackBarColor(context, color);
  final colorScheme = Theme.of(context).colorScheme;

  // Determine text color based on background
  final textColor = resolvedColor == colorScheme.error
      ? colorScheme.onError
      : colorScheme.onPrimary;

  return SnackBar(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    content: Text(message, style: TextStyle(color: textColor)),
    duration: resolvedDuration,
    backgroundColor: resolvedColor,
    action: SnackBarAction(
      key: const Key('dismiss'),
      label: 'Dismiss',
      textColor: textColor.withValues(alpha: 0.8),
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );
}
