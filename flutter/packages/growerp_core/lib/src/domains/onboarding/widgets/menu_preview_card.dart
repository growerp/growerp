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
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:genui/genui.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

class MenuPreviewCard extends StatefulWidget {
  const MenuPreviewCard({
    super.key,
    required this.headline,
    required this.menuItems,
    required this.onSubmit,
    required this.classificationId,
    required this.onFinalize,
    this.name,
  });

  final String headline;
  final List<Map<String, dynamic>> menuItems;
  final Future<void> Function(String text) onSubmit;
  final String classificationId;
  final Future<void> Function(OnboardingMenuConfig) onFinalize;
  final String? name;

  static CatalogItem catalogItem({
    required Future<void> Function(String) onSubmit,
    required String classificationId,
    required Future<void> Function(OnboardingMenuConfig) onFinalize,
  }) =>
      CatalogItem(
        name: 'MenuPreviewCard',
        dataSchema: Schema.object(
          description: 'Preview of the generated menu for user confirmation.',
          properties: {
            'headline': Schema.string(),
            'name': Schema.string(),
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
          required: ['headline', 'menuItems'],
        ),
        widgetBuilder: (ctx) {
          final data = ctx.data as Map<String, dynamic>;
          final rawItems = (data['menuItems'] as List? ?? []);
          final cleanItems = rawItems.whereType<Map<String, dynamic>>().toList();
          return MenuPreviewCard(
            headline: data['headline'] as String,
            name: data['name'] as String?,
            menuItems: cleanItems,
            classificationId: classificationId,
            onSubmit: onSubmit,
            onFinalize: onFinalize,
          );
        },
      );

  @override
  State<MenuPreviewCard> createState() => _MenuPreviewCardState();
}

class _MenuPreviewCardState extends State<MenuPreviewCard> {
  bool _adjusting = false;
  bool _submitting = false;
  final _adjustController = TextEditingController();

  @override
  void dispose() {
    _adjustController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    final items = widget.menuItems
        .whereType<Map<String, dynamic>>()
        .map((m) => OnboardingMenuItem(
              title: m['title'] as String,
              iconName: m['iconName'] as String?,
              route: m['route'] as String,
              widgetName: m['widgetName'] as String,
              sequenceNum: m['sequenceNum'] as int?,
              tileType: m['tileType'] as String?,
            ))
        .toList();
    try {
      await widget.onFinalize(OnboardingMenuConfig(
        name: widget.name ?? widget.classificationId,
        classificationId: widget.classificationId,
        menuItems: items,
      ));
    } catch (e) {
      debugPrint('onFinalize failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _submitAdjust() async {
    final text = _adjustController.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    await widget.onSubmit('adjust: $text');
    if (mounted) {
      setState(() {
        _submitting = false;
        _adjusting = false;
        _adjustController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.headline,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.menuItems.map((item) {
                final title = item['title'] as String;
                final iconName = item['iconName'] as String?;
                return Chip(
                  avatar: iconName != null
                      ? const Icon(Icons.dashboard, size: 16)
                      : null,
                  label: Text(title),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_adjusting) ...[
              FormBuilderTextField(
                name: 'adjust',
                controller: _adjustController,
                decoration: const InputDecoration(
                  hintText: 'What would you like to change?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _adjusting = false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitting ? null : _submitAdjust,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _adjusting = true),
                    child: const Text('Adjust'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitting ? null : _confirm,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Looks good!'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
