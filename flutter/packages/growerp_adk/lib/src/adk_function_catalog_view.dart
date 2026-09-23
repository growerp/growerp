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

/// Function catalog: every "_NA_" template agent function across every real
/// team (the toy Agent Demo team is excluded server-side), grouped by team,
/// with a checkbox to add just the ones the admin wants — instead of a single
/// all-or-nothing "load the whole team" button.
///
/// Reachable from Agent Control (`AdkAgentListView`'s toolbar); on save,
/// clones exactly the newly-checked functions into this tenant via
/// `AdkConfigService.loadAgentTeam(adkAgentConfigIds: ...)`.
class AdkFunctionCatalogView extends StatefulWidget {
  const AdkFunctionCatalogView({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 640,
            height: 640,
            child: const AdkFunctionCatalogView(),
          ),
        ),
      );

  @override
  State<AdkFunctionCatalogView> createState() =>
      _AdkFunctionCatalogViewState();
}

class _AdkFunctionCatalogViewState extends State<AdkFunctionCatalogView> {
  List<AdkAgentCatalogFunction> _functions = [];
  final Set<String> _newlySelected = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkConfigService.create();
      final list = await svc.agentCatalog();
      if (mounted) {
        setState(() {
          _functions = list;
          _newlySelected.removeWhere(
            (id) => !list.any(
              (f) => f.adkAgentConfigId == id && !f.alreadyEnabled,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _riskLabel(AdkAgentCatalogFunction f) {
    if (f.writePolicy == 'allow') return 'auto write';
    if (f.writePolicy == 'approve') return 'approval-gated write';
    return 'read-only';
  }

  Color _riskColor(AdkAgentCatalogFunction f) {
    if (f.writePolicy == 'allow') return Colors.red;
    if (f.writePolicy == 'approve') return Colors.orange;
    return Colors.green;
  }

  Future<void> _addSelected() async {
    if (_newlySelected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final svc = await AdkConfigService.create();
      await svc.loadAgentTeam(adkAgentConfigIds: _newlySelected.toList());
      final added = _newlySelected.length;
      _newlySelected.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $added function(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _suggestFunction() async {
    final descCtrl = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suggest a function'),
        content: TextField(
          key: const Key('suggestFunctionDescription'),
          controller: descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe what you want an agent to do, e.g. '
                '"remind customers about overdue invoices"',
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancelSuggestFunction'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('checkSuggestFunction'),
            onPressed: () => Navigator.pop(dialogContext, descCtrl.text.trim()),
            child: const Text('Check'),
          ),
        ],
      ),
    );
    if (description == null || description.isEmpty || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    AdkFunctionSuggestion? suggestion;
    Object? error;
    try {
      final svc = await AdkConfigService.create();
      suggestion = await svc.suggestFunction(
        description,
        screenCatalogJson: jsonEncode(WidgetRegistry.getWidgetCatalog()),
      );
    } catch (e) {
      error = e;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) return;

    if (error != null || suggestion == null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Could not check feasibility'),
          content: Text('$error'),
          actions: [
            TextButton(
              key: const Key('dismissSuggestError'),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (suggestion.outcome == 'newFunction' && suggestion.draft != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('This looks feasible'),
          content: Text(suggestion!.message),
          actions: [
            TextButton(
              key: const Key('dismissSuggestFeasible'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              key: const Key('reviewSuggestFeasible'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Review and create'),
            ),
          ],
        ),
      );
      if (mounted) {
        await AdkAgentConfigDialog.show(context, existing: suggestion.draft);
      }
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            suggestion!.outcome == 'navigation'
                ? 'Already possible'
                : 'Not currently possible',
          ),
          content: Text(suggestion.message),
          actions: [
            TextButton(
              key: const Key('dismissSuggestOutcome'),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Function catalog',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('suggestFunction'),
                onPressed: _suggestFunction,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Suggest a function'),
              ),
              IconButton(
                key: const Key('closeFunctionCatalog'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('addSelectedFunctions'),
              onPressed: (_newlySelected.isEmpty || _saving)
                  ? null
                  : _addSelected,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Add selected (${_newlySelected.length})'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_functions.isEmpty) {
      return const Center(child: Text('No catalog functions available.'));
    }
    final byTeam = <String, List<AdkAgentCatalogFunction>>{};
    for (final f in _functions) {
      byTeam.putIfAbsent(f.teamName ?? 'Other', () => []).add(f);
    }
    return ListView(
      key: const Key('functionCatalogList'),
      children: [
        for (final entry in byTeam.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final f in entry.value)
            CheckboxListTile(
              key: Key('function_${f.adkAgentConfigId}'),
              value: f.alreadyEnabled || _newlySelected.contains(
                f.adkAgentConfigId,
              ),
              onChanged: f.alreadyEnabled
                  ? null
                  : (checked) {
                      setState(() {
                        if (checked == true) {
                          _newlySelected.add(f.adkAgentConfigId);
                        } else {
                          _newlySelected.remove(f.adkAgentConfigId);
                        }
                      });
                    },
              title: Text(f.agentName),
              subtitle: Text(f.description ?? ''),
              secondary: Chip(
                label: Text(
                  f.alreadyEnabled ? 'enabled' : _riskLabel(f),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor:
                    f.alreadyEnabled ? Colors.grey : _riskColor(f),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ],
    );
  }
}
