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
import 'package:json_schema_builder/json_schema_builder.dart';

class OptionsCard extends StatefulWidget {
  const OptionsCard({
    super.key,
    required this.question,
    required this.options,
    required this.multiSelect,
    required this.onSubmit,
  });

  final String question;
  final List<String> options;
  final bool multiSelect;
  final Future<void> Function(String text) onSubmit;

  static CatalogItem catalogItem(Future<void> Function(String) onSubmit) =>
      CatalogItem(
        name: 'OptionsCard',
        dataSchema: Schema.object(
          description: 'Multiple-choice question with LLM-generated options.',
          properties: {
            'question': Schema.string(),
            'options': Schema.list(items: Schema.string()),
            'multiSelect': Schema.boolean(),
          },
          required: ['question', 'options'],
        ),
        widgetBuilder: (ctx) {
          final data = ctx.data as Map<String, dynamic>;
          return OptionsCard(
            question: data['question'] as String,
            options: (data['options'] as List).cast<String>(),
            multiSelect: data['multiSelect'] as bool? ?? false,
            onSubmit: onSubmit,
          );
        },
      );

  @override
  State<OptionsCard> createState() => _OptionsCardState();
}

class _OptionsCardState extends State<OptionsCard> {
  final Set<String> _selected = {};
  bool _submitting = false;

  void _toggle(String option) {
    setState(() {
      if (widget.multiSelect) {
        if (_selected.contains(option)) {
          _selected.remove(option);
        } else {
          _selected.add(option);
        }
      } else {
        _selected
          ..clear()
          ..add(option);
      }
    });
  }

  void _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _submitting = true);
    final text = widget.multiSelect
        ? 'Selected: ${_selected.join(', ')}'
        : _selected.first;
    await widget.onSubmit(text);
    if (mounted) setState(() => _submitting = false);
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
              widget.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.map((opt) {
                final selected = _selected.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: selected,
                  onSelected: _submitting ? null : (_) => _toggle(opt),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: (_selected.isEmpty || _submitting) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
