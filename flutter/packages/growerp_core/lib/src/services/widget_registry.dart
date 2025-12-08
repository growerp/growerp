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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';

/// Type definition for widget builder functions
/// Named GrowerpWidgetBuilder to avoid conflict with Flutter's WidgetBuilder
typedef GrowerpWidgetBuilder = Widget Function(Map<String, dynamic>? args);

/// Metadata for a registered widget (for AI navigation)
class WidgetMetadata {
  /// Unique widget name (e.g., 'SalesInvoiceList')
  final String widgetName;

  /// Human-readable description for AI context
  final String description;

  /// Keywords for AI matching (e.g., ['invoice', 'bill', 'AR'])
  final List<String> keywords;

  /// Parameter descriptions for AI
  /// e.g., {'status': 'Filter: open, paid, cancelled'}
  final Map<String, String> parameters;

  /// The widget builder function
  final GrowerpWidgetBuilder builder;

  const WidgetMetadata({
    required this.widgetName,
    required this.description,
    this.keywords = const [],
    this.parameters = const {},
    required this.builder,
  });

  /// Convert to JSON for AI context
  Map<String, dynamic> toJson() => {
    'widgetName': widgetName,
    'description': description,
    'keywords': keywords,
    'parameters': parameters,
  };
}

/// Composable Widget Registry with AI discovery support
///
/// Each package exports its widgets via a function like:
/// ```dart
/// Map<String, WidgetBuilder> getUserCompanyWidgets() => {...}
/// ```
///
/// Apps compose them in main.dart:
/// ```dart
/// WidgetRegistry.register(getUserCompanyWidgets());
/// ```
class WidgetRegistry {
  static final Map<String, WidgetMetadata> _widgets = {};

  /// Register widgets from a package (backward compatible)
  ///
  /// Creates basic metadata without descriptions
  static void register(Map<String, GrowerpWidgetBuilder> widgets) {
    for (final entry in widgets.entries) {
      _widgets[entry.key] = WidgetMetadata(
        widgetName: entry.key,
        description: entry.key, // Default to widget name
        builder: entry.value,
      );
    }
  }

  /// Register widget with full metadata (for AI discovery)
  static void registerWithMetadata(WidgetMetadata metadata) {
    _widgets[metadata.widgetName] = metadata;
  }

  /// Register multiple widgets with metadata
  static void registerAllWithMetadata(List<WidgetMetadata> metadataList) {
    for (final metadata in metadataList) {
      _widgets[metadata.widgetName] = metadata;
    }
  }

  /// Clear all registered widgets (useful for testing)
  static void clear() {
    _widgets.clear();
  }

  /// Get a widget by name
  ///
  /// Returns a fallback widget if not found
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]) {
    final metadata = _widgets[widgetName];
    if (metadata != null) {
      return metadata.builder(args);
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

  /// Get metadata for a widget
  static WidgetMetadata? getMetadata(String widgetName) => _widgets[widgetName];

  /// Search widgets by keywords (for AI matching)
  ///
  /// Returns widgets matching any of the given keywords
  static List<WidgetMetadata> searchByKeywords(List<String> searchTerms) {
    final lowerTerms = searchTerms.map((t) => t.toLowerCase()).toList();
    return _widgets.values.where((meta) {
      // Check widget name
      if (lowerTerms.any((t) => meta.widgetName.toLowerCase().contains(t))) {
        return true;
      }
      // Check description
      if (lowerTerms.any((t) => meta.description.toLowerCase().contains(t))) {
        return true;
      }
      // Check keywords
      return meta.keywords.any(
        (k) => lowerTerms.any((t) => k.toLowerCase().contains(t)),
      );
    }).toList();
  }

  /// Get widget catalog as JSON string (for AI context)
  ///
  /// Provides AI with available screens and their parameters
  static String getWidgetCatalog() {
    final catalog = _widgets.values.map((m) => m.toJson()).toList();
    return jsonEncode(catalog);
  }

  /// Get all metadata (for AI system prompt building)
  static List<WidgetMetadata> get allMetadata => _widgets.values.toList();
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
