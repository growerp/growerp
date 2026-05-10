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
import 'package:json_schema_builder/json_schema_builder.dart';

class WelcomeCard extends StatefulWidget {
  const WelcomeCard({
    super.key,
    required this.greeting,
    required this.inputPrompt,
    this.hintText,
    required this.onSubmit,
  });

  final String greeting;
  final String inputPrompt;
  final String? hintText;
  final Future<void> Function(String text) onSubmit;

  static CatalogItem catalogItem(Future<void> Function(String) onSubmit) =>
      CatalogItem(
        name: 'WelcomeCard',
        dataSchema: Schema.object(
          description: 'Free-text welcome card asking about the user\'s business.',
          properties: {
            'greeting': Schema.string(),
            'inputPrompt': Schema.string(),
            'hintText': Schema.string(),
          },
          required: ['greeting', 'inputPrompt'],
        ),
        widgetBuilder: (ctx) {
          final data = ctx.data as Map<String, dynamic>;
          return WelcomeCard(
            greeting: data['greeting'] as String,
            inputPrompt: data['inputPrompt'] as String,
            hintText: data['hintText'] as String?,
            onSubmit: onSubmit,
          );
        },
      );

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _textController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    await widget.onSubmit(text);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.greeting,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(widget.inputPrompt),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                controller: _textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please describe your business' : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
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
      ),
    );
  }
}
