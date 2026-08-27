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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// System Defaults Screen — GrowERP wide defaults, not tenant specific.
/// Only a system support user can save: the backend update#SystemDefault service
/// errors out for anybody else.
class SystemDefaultsDialog extends StatefulWidget {
  const SystemDefaultsDialog({super.key});

  @override
  State<SystemDefaultsDialog> createState() => _SystemDefaultsDialogState();
}

class _SystemDefaultsDialogState extends State<SystemDefaultsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tokenLimitCtrl = TextEditingController();
  String? _aiModelName;
  String _aiProvider = '';
  bool _isLoading = true;
  bool _isSaving = false;

  RestClient? _restClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restClient = context.read<RestClient>();
      _loadDefaults();
    });
  }

  @override
  void dispose() {
    _tokenLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final d = await _restClient!.getSystemDefault();
      if (!mounted) return;
      _tokenLimitCtrl.text = d.llmMonthlyTokenLimit?.toString() ?? '';
      // a stored model outside the shared list (an OpenAI model, or one added
      // after this release) stays selected: _modelItems() adds an entry for it
      if (d.aiModelName.isEmpty) {
        _aiModelName = null;
        _aiProvider = '';
      } else {
        _aiModelName = d.aiModelName;
        _aiProvider = d.aiProvider.isNotEmpty
            ? d.aiProvider
            : providerForModel(d.aiModelName);
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to load defaults: $e',
          Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDefaults() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final modelId = _selectedModelId();
      await _restClient!.updateSystemDefault({
        'llmMonthlyTokenLimit': _tokenLimitCtrl.text.isEmpty
            ? null
            : int.tryParse(_tokenLimitCtrl.text),
        'aiModelName': modelId,
        'aiProvider': modelId.isEmpty ? '' : _aiProvider,
      });
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Defaults saved successfully',
          Theme.of(context).colorScheme.primary,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to save defaults: $e',
          Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      key: const Key('SystemDefaultsDialog'),
      padding: EdgeInsets.all(isPhone ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isPhone ? 600 : 1000),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'System Defaults',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'GrowERP wide defaults, applied to all tenants.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                _llmSection(),
                SizedBox(height: 32),
                Center(child: _saveButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The model id to store: '' means "no system wide default".
  String _selectedModelId() => _aiModelName ?? '';

  /// The full model list: this screen is cross tenant, and API keys are per
  /// tenant, so there is no key presence to filter on here.
  List<DropdownMenuItem<String>> _modelItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: null,
        child: Text('No system default'),
      ),
      ...llmModels.map((m) => DropdownMenuItem<String>(
            value: m.modelId,
            child: Text('${m.modelId}  (${m.provider})'),
          )),
    ];
    // a stored model that is no longer in the shared list keeps its entry, so the
    // dropdown never holds a value without a matching item
    final saved = _aiModelName;
    if (saved != null && !items.any((i) => i.value == saved)) {
      items.add(DropdownMenuItem<String>(
        value: saved,
        child: Text('$saved  ($_aiProvider)'),
      ));
    }
    return items;
  }

  Widget _llmSection() {
    return GroupingDecorator(
      decoratorKey: const Key('llmDefaultsSection'),
      labelText: 'System LLM',
      icon: Icons.psychology,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Applies only to tenants without their own LLM API key. '
            'The system API keys come from the server environment.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('aiModelName'),
            initialValue: _aiModelName,
            decoration: const InputDecoration(
              labelText: 'Default AI Model',
              helperText: 'Used by tenants that did not pick a model of their '
                  'own. API keys stay per tenant.',
            ),
            items: _modelItems(),
            onChanged: (v) => setState(() {
              _aiModelName = v;
              _aiProvider = v == null
                  ? ''
                  : llmModels
                      .firstWhere((m) => m.modelId == v,
                          orElse: () => LlmModel(providerForModel(v), v))
                      .provider;
            }),
          ),
          SizedBox(height: 16),
          TextFormField(
            key: const Key('llmMonthlyTokenLimit'),
            controller: _tokenLimitCtrl,
            decoration: const InputDecoration(
              labelText: 'System LLM Monthly Token Limit',
              hintText: 'e.g. 100000',
              helperText: 'Free tokens per tenant per calendar month. '
                  'Empty or 0 = unlimited.',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final number = int.tryParse(value);
              if (number == null || number < 0) {
                return 'Enter a positive number or leave empty';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        key: const Key('saveDefaults'),
        icon: _isSaving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Defaults'),
        onPressed: _isSaving ? null : _saveDefaults,
      ),
    );
  }
}
