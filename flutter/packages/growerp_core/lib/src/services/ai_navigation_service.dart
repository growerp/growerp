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
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'widget_registry.dart';

/// Simple data class for menu option info (to avoid model dependency)
class MenuItemInfo {
  final String title;
  final String route;
  final String widgetName;

  const MenuItemInfo({
    required this.title,
    required this.route,
    required this.widgetName,
  });
}

/// Intent returned by AI for navigation
class NavigationIntent {
  /// Widget name to navigate to (e.g., 'SalesInvoiceList')
  final String widgetName;

  /// The actual route path (e.g., '/users', '/accounting/ledger')
  /// If provided, this takes precedence over widgetName for navigation
  final String? route;

  /// Arguments to pass to the widget (e.g., {'status': 'open'})
  final Map<String, dynamic> args;

  /// Confidence score from AI (0.0 to 1.0)
  final double confidence;

  /// Human-readable description of what AI understood
  final String? explanation;

  const NavigationIntent({
    required this.widgetName,
    this.route,
    this.args = const {},
    this.confidence = 1.0,
    this.explanation,
  });

  factory NavigationIntent.fromJson(Map<String, dynamic> json) {
    return NavigationIntent(
      widgetName: json['widgetName'] as String? ?? '',
      route: json['route'] as String?,
      args: Map<String, dynamic>.from(json['args'] as Map? ?? {}),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      explanation: json['explanation'] as String?,
    );
  }

  /// Invalid intent (no match found)
  static const NavigationIntent none = NavigationIntent(
    widgetName: '',
    confidence: 0.0,
  );

  bool get isValid => widgetName.isNotEmpty && confidence > 0.3;
}

/// AI-powered navigation service using Google Gemini
///
/// Parses natural language prompts like "show open invoices"
/// and returns NavigationIntent with route and widget name.
class AiNavigationService {
  final String apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final String _model = 'gemini-2.0-flash';

  /// Optional menu configuration for route-aware navigation
  List<MenuItemInfo>? _menuItems;

  AiNavigationService({required this.apiKey});

  /// Set the current menu configuration for route-aware AI navigation
  ///
  /// When set, the AI will use actual routes from the menu instead of
  /// deriving routes from widget names.
  void setMenuConfiguration(dynamic menuConfig) {
    if (menuConfig == null) {
      _menuItems = null;
      return;
    }

    // Extract menu options from MenuConfiguration
    // Using dynamic to avoid import dependency on growerp_models
    try {
      final options = menuConfig.menuItems as List<dynamic>?;
      if (options != null) {
        _menuItems = options
            .where((o) => o.isActive == true && o.route != null)
            .map(
              (o) => MenuItemInfo(
                title: o.title as String? ?? '',
                route: o.route as String? ?? '',
                widgetName: o.widgetName as String? ?? '',
              ),
            )
            .toList();
        debugPrint(
          'AiNavigationService: Loaded ${_menuItems?.length ?? 0} menu options for AI context',
        );
      }
    } catch (e) {
      debugPrint('AiNavigationService: Failed to parse menu config: $e');
      _menuItems = null;
    }
  }

  /// Parse a natural language prompt into navigation intent
  ///
  /// Example:
  /// ```dart
  /// final intent = await service.parsePrompt('show open invoices');
  /// // Returns: NavigationIntent(route: '/invoices', widgetName: 'SalesInvoiceList')
  /// ```
  Future<NavigationIntent> parsePrompt(String prompt) async {
    if (apiKey.isEmpty) {
      debugPrint('AiNavigationService: No API key configured');
      return NavigationIntent.none;
    }

    try {
      final systemPrompt = _buildSystemPrompt();
      final response = await _callGemini(systemPrompt, prompt);
      return _parseResponse(response);
    } catch (e) {
      debugPrint('AiNavigationService error: $e');
      return NavigationIntent.none;
    }
  }

  /// Build system prompt - uses menu config if available, otherwise widget registry
  String _buildSystemPrompt() {
    if (_menuItems != null && _menuItems!.isNotEmpty) {
      return _buildMenuBasedPrompt();
    }
    return _buildWidgetRegistryPrompt();
  }

  /// Build prompt from actual menu configuration with routes
  String _buildMenuBasedPrompt() {
    final menuList = _menuItems!
        .map(
          (o) => '- "${o.title}": route="${o.route}", widget="${o.widgetName}"',
        )
        .join('\n');

    return '''
You are a navigation assistant for GrowERP, a business management application.

Your task is to parse user requests and determine which screen to navigate to.

AVAILABLE MENU OPTIONS (with actual routes):
$menuList

RULES:
1. Match user requests to the most appropriate menu option based on title and widget name
2. ALWAYS return the exact route from the menu - do not make up routes
3. If ambiguous between sales/purchase, prefer sales
4. If no good match found, return empty route and widgetName

OUTPUT FORMAT (JSON only, no markdown):
{
  "route": "/actual-route-from-menu",
  "widgetName": "WidgetName",
  "args": {},
  "confidence": 0.95,
  "explanation": "Brief explanation"
}

IMPORTANT: Only use routes that exist in the AVAILABLE MENU OPTIONS above.
''';
  }

  /// Build prompt from widget registry (fallback when no menu config)
  String _buildWidgetRegistryPrompt() {
    final catalog = WidgetRegistry.getWidgetCatalog();
    return '''
You are a navigation assistant for GrowERP, a business management application.

Your task is to parse user requests and determine which screen to navigate to.

AVAILABLE SCREENS:
$catalog

RULES:
1. Match user requests to the most appropriate screen based on keywords and descriptions
2. Extract any filter parameters mentioned (e.g., "open" = status filter)
3. If ambiguous between sales/purchase, prefer sales
4. If no good match found, return empty widgetName

OUTPUT FORMAT (JSON only, no markdown):
{
  "widgetName": "WidgetName",
  "args": {"param1": "value1"},
  "confidence": 0.95,
  "explanation": "Brief explanation"
}

EXAMPLES:
- "show invoices" → {"widgetName": "SalesInvoiceList", "args": {}, "confidence": 0.9, "explanation": "Showing sales invoices"}
- "open purchase orders" → {"widgetName": "PurchaseOrderList", "args": {}, "confidence": 0.95, "explanation": "Showing purchase orders"}
''';
  }

  /// Call Gemini API
  Future<String> _callGemini(String systemPrompt, String userPrompt) async {
    final url = Uri.parse(
      '$_baseUrl/models/$_model:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$systemPrompt\n\nUser request: $userPrompt'},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 200},
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error: ${response.statusCode} ${response.body}',
      );
    }

    final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = jsonResponse['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return parts[0]['text'] as String? ?? '';
  }

  /// Parse Gemini response into NavigationIntent
  NavigationIntent _parseResponse(String response) {
    // Clean up response (remove markdown code blocks if present)
    var cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final intent = NavigationIntent.fromJson(json);
      debugPrint(
        'AiNavigationService: AI navigation to "${intent.route ?? intent.widgetName}"',
      );

      // Validate widget exists
      if (!WidgetRegistry.hasWidget(intent.widgetName)) {
        debugPrint(
          'AiNavigationService: Widget "${intent.widgetName}" not found',
        );
        return NavigationIntent.none;
      }

      return intent;
    } catch (e) {
      debugPrint('AiNavigationService: Failed to parse response: $cleaned');
      return NavigationIntent.none;
    }
  }

  /// Quick search without AI (fallback for simple matches)
  NavigationIntent searchLocal(String query) {
    final terms = query.toLowerCase().split(' ');
    final matches = WidgetRegistry.searchByKeywords(terms);

    if (matches.isEmpty) {
      return NavigationIntent.none;
    }

    // Return best match
    return NavigationIntent(
      widgetName: matches.first.widgetName,
      confidence: 0.7,
      explanation: 'Local match: ${matches.first.description}',
    );
  }
}
