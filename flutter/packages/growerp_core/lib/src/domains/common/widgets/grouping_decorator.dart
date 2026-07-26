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

/// A styled InputDecorator for grouping form fields with consistent borders.
///
/// This widget provides a consistent look for grouping containers across the app,
/// following the modern Stitch design system with card-based layouts.
///
/// Example usage:
/// ```dart
/// GroupingDecorator(
///   labelText: 'User Information',
///   child: Column(
///     children: [
///       TextFormField(...),
///       TextFormField(...),
///     ],
///   ),
/// )
/// ```
class GroupingDecorator extends StatelessWidget {
  /// The label text displayed at the top of the grouping box.
  final String labelText;

  /// The child widget to display inside the grouping box.
  final Widget child;

  /// Optional key for widget testing.
  final Key? decoratorKey;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Whether to use the new Stitch card-based design (default: true)
  final bool useCardStyle;

  const GroupingDecorator({
    super.key,
    required this.labelText,
    required this.child,
    this.decoratorKey,
    this.icon,
    this.useCardStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useCardStyle) {
      return _buildCardStyle(context);
    }
    return _buildLegacyStyle(context);
  }

  Widget _buildCardStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: decoratorKey,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Material(
            type: MaterialType.transparency,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyStyle(BuildContext context) {
    return InputDecorator(
      key: decoratorKey,
      decoration: InputDecoration(
        labelText: labelText,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
      ),
      child: child,
    );
  }
}
