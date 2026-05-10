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
import 'package:genui/genui.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Invisible widget — triggers onFinalize callback when rendered by genui.
/// The AI calls this as the final step; it is never shown to the user.
class FinalizeMenuWidget {
  static CatalogItem catalogItem(
    void Function(OnboardingMenuConfig) onFinalize,
  ) =>
      CatalogItem(
        name: 'FinalizeMenu',
        dataSchema: Schema.object(
          description: 'Final menu configuration. Triggers menu save.',
          properties: {
            'name': Schema.string(),
            'classificationId': Schema.string(),
            'menuItems': Schema.list(
              items: Schema.object(
                properties: {
                  'title': Schema.string(),
                  'iconName': Schema.string(),
                  'route': Schema.string(),
                  'widgetName': Schema.string(),
                  'sequenceNum': Schema.integer(),
                  'tileType': Schema.string(),
                },
                required: ['title', 'route', 'widgetName'],
              ),
            ),
          },
          required: ['name', 'classificationId', 'menuItems'],
        ),
        widgetBuilder: (ctx) {
          final data = ctx.data as Map<String, dynamic>;
          try {
            // AI occasionally emits a bare string as the last menuItem
            // (e.g. "RevenueExpenseChart" instead of a full object).
            // Filter those out so fromJson never throws on that.
            final rawItems = (data['menuItems'] as List? ?? []);
            final cleanItems =
                rawItems.whereType<Map<String, dynamic>>().toList();
            final cleanData = Map<String, dynamic>.from(data)
              ..['menuItems'] = cleanItems;
            final config = OnboardingMenuConfig.fromJson(cleanData);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onFinalize(config);
            });
          } catch (e, st) {
            debugPrint('FinalizeMenuWidget parse error: $e\n$st');
          }
          return const SizedBox.shrink();
        },
      );
}
