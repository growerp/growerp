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
import 'package:growerp_models/growerp_models.dart';

/// Type definition for widget builder functions
/// Named GrowerpWidgetBuilder to avoid conflict with Flutter's WidgetBuilder
typedef GrowerpWidgetBuilder = Widget Function(Map<String, dynamic>? args);

/// Composable Widget Registry
///
/// Each package exports its widgets via a function like:
/// ```dart
/// Map<String, WidgetBuilder> getUserCompanyWidgets() => {...}
/// ```
///
/// Apps compose them in main.dart:
/// ```dart
/// WidgetRegistry.register(getUserCompanyWidgets());
/// WidgetRegistry.register(getCatalogWidgets());
/// ```
class WidgetRegistry {
  static final Map<String, GrowerpWidgetBuilder> _widgets = {};

  /// Register widgets from a package
  ///
  /// Example:
  /// ```dart
  /// WidgetRegistry.register(getUserCompanyWidgets());
  /// ```
  static void register(Map<String, GrowerpWidgetBuilder> widgets) {
    _widgets.addAll(widgets);
  }

  /// Clear all registered widgets (useful for testing)
  static void clear() {
    _widgets.clear();
  }

  /// Get a widget by name
  ///
  /// Returns a fallback widget if not found
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]) {
    final builder = _widgets[widgetName];
    if (builder != null) {
      return builder(args);
    }
    debugPrint('WidgetRegistry: Widget "$widgetName" not found');
    return Center(
      child: Text(
        'Widget "$widgetName" not found',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  /// Check if a widget is registered
  static bool hasWidget(String widgetName) => _widgets.containsKey(widgetName);

  /// Get all registered widget names (for debugging)
  static List<String> get registeredWidgets => _widgets.keys.toList();
}

// ============================================================================
// Helper functions for parsing common types
// ============================================================================

/// Parse a key from args
Key? getKeyFromArgs(Map<String, dynamic>? args) {
  if (args != null && args.containsKey('key')) {
    return Key(args['key']);
  }
  return null;
}

/// Parse Role from string
Role parseRole(String? roleName) {
  if (roleName == null) return Role.unknown;
  try {
    return Role.values.firstWhere(
      (e) => e.name.toLowerCase() == roleName.toLowerCase(),
      orElse: () => Role.unknown,
    );
  } catch (_) {
    return Role.unknown;
  }
}

/// Parse FinDocType from string
FinDocType parseFinDocType(String? typeName) {
  if (typeName == null) return FinDocType.unknown;
  try {
    return FinDocType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeName.toLowerCase(),
      orElse: () => FinDocType.unknown,
    );
  } catch (_) {
    return FinDocType.unknown;
  }
}
