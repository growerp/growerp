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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'adk_agent_config_dialog.dart';
import 'adk_config_service.dart';

/// Reusable "Suggest a function" panel: describe a capability in free text,
/// get a feasibility check against real services and (in a live chat session)
/// the screen catalog, and — only on an explicit "Review and create" — open
/// the normal agent-creation dialog pre-filled from the result. Never creates
/// anything on its own.
///
/// Embedded inline (e.g. as a tab) rather than behind its own button+dialog,
/// so the result renders in place instead of stacking dialogs.
///
/// [showOwnerField] shows a "Tenant owner party ID" field so GrowERP support
/// can test on behalf of a specific tenant (their own session has no real
/// tenant of its own) — the backend ignores that override for anyone not in
/// GROWERP_M_SYSTEM, so this is a no-op if shown to a normal tenant admin.
class AdkSuggestFunctionPanel extends StatefulWidget {
  final bool showOwnerField;

  const AdkSuggestFunctionPanel({super.key, this.showOwnerField = false});

  @override
  State<AdkSuggestFunctionPanel> createState() =>
      _AdkSuggestFunctionPanelState();
}

class _AdkSuggestFunctionPanelState extends State<AdkSuggestFunctionPanel> {
  final _ownerCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _checking = false;
  AdkFunctionSuggestion? _result;
  String? _error;

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final description = _descCtrl.text.trim();
    if (description.isEmpty) return;
    setState(() {
      _checking = true;
      _result = null;
      _error = null;
    });
    try {
      final svc = await AdkConfigService.create();
      final result = await svc.suggestFunction(
        description,
        screenCatalogJson: jsonEncode(WidgetRegistry.getWidgetCatalog()),
        ownerPartyId: widget.showOwnerField && _ownerCtrl.text.trim().isNotEmpty
            ? _ownerCtrl.text.trim()
            : null,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _reviewAndCreate() async {
    final draft = _result?.draft;
    if (draft == null) return;
    await AdkAgentConfigDialog.show(context, existing: draft);
  }

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'newFunction':
        return Colors.green;
      case 'navigation':
        return Colors.blue;
      case 'notPossible':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _outcomeLabel(String outcome) {
    switch (outcome) {
      case 'newFunction':
        return 'Feasible';
      case 'navigation':
        return 'Already possible';
      case 'notPossible':
        return 'Not currently possible';
      default:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe a capability you want an agent to have. This checks it '
            'against real services before anything is created — nothing is '
            'saved until you explicitly review and create it.',
          ),
          const SizedBox(height: 16),
          if (widget.showOwnerField) ...[
            TextField(
              key: const Key('suggestFunctionOwnerPartyId'),
              controller: _ownerCtrl,
              decoration: const InputDecoration(
                labelText: 'Tenant owner party ID (support only)',
                hintText: 'Leave blank to use your own',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('suggestFunctionDescription'),
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Describe the function',
              hintText:
                  'e.g. "remind customers about overdue invoices"',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('checkSuggestFunction'),
            onPressed: _checking ? null : _check,
            child: _checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Check'),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Could not check feasibility: $_error'),
              ),
            ),
          if (_result != null)
            Card(
              key: const Key('suggestFunctionResult'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(
                        _outcomeLabel(_result!.outcome),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _outcomeColor(_result!.outcome),
                    ),
                    const SizedBox(height: 8),
                    Text(_result!.message),
                    if (_result!.outcome == 'newFunction' &&
                        _result!.draft != null) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('reviewAndCreateSuggested'),
                        onPressed: _reviewAndCreate,
                        child: const Text('Review and create'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
