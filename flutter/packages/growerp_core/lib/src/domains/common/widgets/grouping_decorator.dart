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

/// A styled InputDecorator for grouping form fields with consistent borders.
///
/// This widget provides a consistent look for grouping containers across the app,
/// with theme-aware border colors and 25.0 radius rounded corners.
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

  const GroupingDecorator({
    super.key,
    required this.labelText,
    required this.child,
    this.decoratorKey,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outline;
    final focusColor = Theme.of(context).colorScheme.primary;

    return InputDecorator(
      key: decoratorKey,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(color: focusColor, width: 2),
        ),
      ),
      child: child,
    );
  }
}
