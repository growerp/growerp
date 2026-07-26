/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
  // Resolve ScaffoldMessengerState eagerly so the callback never calls
  // ScaffoldMessenger.of() on a potentially deactivated context.
  final scaffoldMessenger = ScaffoldMessenger.of(context);

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
        scaffoldMessenger.hideCurrentSnackBar();
      },
    ),
  );
}
