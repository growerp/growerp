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
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growerp_core/growerp_core.dart';

/// AI tab of System Setup: the LLM provider API keys of this tenant, the model
/// used for generation, and the monthly token cap.
///
/// Saves only the AI slice: update#SystemSettings leaves the fields it is not
/// sent alone, so the email settings of the neighbouring tab are untouched.
class SystemSetupAiView extends StatefulWidget {
  /// Called after a successful save, used by [SystemSetupDialog] to pop when it
  /// is shown modally.
  final VoidCallback? onSaved;

  /// False when embedded next to another section, which then draws the outer
  /// scroll view and padding.
  final bool standalone;

  const SystemSetupAiView({super.key, this.onSaved, this.standalone = true});

  @override
  State<SystemSetupAiView> createState() => _SystemSetupAiViewState();
}

class _SystemSetupAiViewState extends State<SystemSetupAiView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  /// Dynamic list of {providerCtrl, apiKeyCtrl, obscure, apiKeyIsSet}
  final List<Map<String, dynamic>> _llmRows = [];
  String? _aiModelName;
  String _aiProvider = '';

  /// The tenant's own monthly cap, editable only while running on an own key.
  final _ownTokenLimitCtrl = TextEditingController();

  /// Read-only: free allowance in effect and what was used of it this month.
  final _systemTokenLimitCtrl = TextEditingController();
  int? _systemTokenLimit;
  int _tokensUsed = 0;

  RestClient? _restClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restClient = context.read<RestClient>();
      _loadSettings();
    });
  }

  @override
  void dispose() {
    for (final row in _llmRows) {
      (row['providerCtrl'] as TextEditingController).dispose();
      (row['apiKeyCtrl'] as TextEditingController).dispose();
    }
    _ownTokenLimitCtrl.dispose();
    _systemTokenLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final s = await _restClient!.getSystemSettings();
      if (!mounted) return;

      // Build LLM rows from llmConfigs list.
      // Fallback 1: pre-migration server returns geminiApiKey flat field.
      // Fallback 2: SharedPreferences local key (old local-only storage).
      var configs = s.llmConfigs;
      if (configs.isEmpty && (s.geminiApiKey?.isNotEmpty ?? false)) {
        configs = [LlmConfig(llmProvider: 'gemini', apiKey: s.geminiApiKey)];
      } else if (configs.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final local = prefs.getString('gemini_api_key');
        if (local != null && local.isNotEmpty) {
          configs = [LlmConfig(llmProvider: 'gemini', apiKey: local)];
          await prefs.remove('gemini_api_key');
        }
      }

      final newRows = configs
          .map(
            (lc) => <String, dynamic>{
              'providerCtrl': TextEditingController(text: lc.llmProvider),
              'apiKeyCtrl': TextEditingController(text: lc.apiKey ?? ''),
              'obscure': true,
              'apiKeyIsSet': (lc.apiKey ?? '').isNotEmpty,
            },
          )
          .toList();

      // Dispose old rows before replacing
      for (final row in _llmRows) {
        (row['providerCtrl'] as TextEditingController).dispose();
        (row['apiKeyCtrl'] as TextEditingController).dispose();
      }
      _llmRows
        ..clear()
        ..addAll(newRows);
      // A stored model that is not in the shared list (an OpenAI model, or one
      // added after this release) keeps its own entry in _modelItems() rather
      // than being silently reset.
      final storedModel = s.aiModelName ?? '';
      if (storedModel.isEmpty) {
        _aiModelName = null;
        _aiProvider = '';
      } else {
        _aiModelName = storedModel;
        _aiProvider = s.aiProvider?.isNotEmpty == true
            ? s.aiProvider!
            : providerForModel(storedModel);
      }
      _systemTokenLimit = s.systemTokenLimit;
      _systemTokenLimitCtrl.text = (s.systemTokenLimit ?? 0) > 0
          ? s.systemTokenLimit.toString()
          : '';
      _tokensUsed = s.tokensUsedThisMonth ?? 0;
      _ownTokenLimitCtrl.text = (s.ownTokenLimit ?? 0) > 0
          ? s.ownTokenLimit.toString()
          : '';
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to load settings: $e',
          Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final llmConfigs = _llmRows
          .where(
            (r) => (r['providerCtrl'] as TextEditingController).text.isNotEmpty,
          )
          .map((r) {
            final provider = (r['providerCtrl'] as TextEditingController).text;
            final apiKey = (r['apiKeyCtrl'] as TextEditingController).text;
            final m = <String, dynamic>{'llmProvider': provider};
            if (apiKey.isNotEmpty && apiKey != '****') m['apiKey'] = apiKey;
            return m;
          })
          .toList();
      final payload = <String, dynamic>{'llmConfigs': llmConfigs};
      payload['aiModelName'] = _selectedModelId();
      payload['aiProvider'] = _selectedModelId().isEmpty ? '' : _aiProvider;
      // only meaningful on an own key; 0 clears the cap. Not sent otherwise, so
      // switching back to the system default never leaves a stale cap behind.
      if (_hasOwnKeyForSelectedModel) {
        payload['ownTokenLimit'] =
            int.tryParse(_ownTokenLimitCtrl.text.trim()) ?? 0;
      }
      await _restClient!.updateSystemSettings(payload);
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Settings saved successfully',
          Theme.of(context).colorScheme.primary,
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to save settings: $e',
          Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _aiSettingsSection(),
          const SizedBox(height: 24),
          Center(child: _saveButton()),
        ],
      ),
    );
    if (!widget.standalone) return form;

    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return SingleChildScrollView(
      key: const Key('SystemSetupAiView'),
      padding: EdgeInsets.all(isPhone ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isPhone ? 600 : 1000),
          child: form,
        ),
      ),
    );
  }

  /// The model id to store: '' for "system default", otherwise the selection.
  String _selectedModelId() => _aiModelName ?? '';

  /// Providers that currently have an API key row in the form. Read from live
  /// form state, not the last server load, so adding a key immediately makes
  /// that provider's models selectable.
  Set<String> _providersWithKey() => _llmRows
      .map((r) => (r['providerCtrl'] as TextEditingController).text.trim())
      .where((p) => p.isNotEmpty)
      .toSet();

  /// Providers with a key that is actually filled in: an empty new row must not
  /// unlock the own token limit below.
  Set<String> _providersWithFilledKey() => _llmRows
      .where(
        (r) =>
            (r['apiKeyCtrl'] as TextEditingController).text.trim().isNotEmpty ||
            r['apiKeyIsSet'] == true,
      )
      .map((r) => (r['providerCtrl'] as TextEditingController).text.trim())
      .where((p) => p.isNotEmpty)
      .toSet();

  /// True when the selected model runs on this tenant's own API key: only then
  /// is the monthly token limit the tenant's own cap rather than the free
  /// allowance set by GrowERP support.
  bool get _hasOwnKeyForSelectedModel {
    final model = _aiModelName;
    if (model == null) return false;
    final provider = _aiProvider.isNotEmpty
        ? _aiProvider
        : providerForModel(model);
    return _providersWithFilledKey().contains(provider);
  }

  List<DropdownMenuItem<String>> _modelItems() {
    final withKey = _providersWithKey();
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: null,
        child: Text(CoreLocalizations.of(context)!.systemDefault),
      ),
    ];
    for (final model in llmModels.where((m) => withKey.contains(m.provider))) {
      items.add(
        DropdownMenuItem<String>(
          value: model.modelId,
          child: Text('${model.modelId}  (${model.provider})'),
        ),
      );
    }
    // a saved model whose key row was removed, or one no longer in the shared
    // list, stays selectable: opening this screen never silently rewrites the
    // stored setting, and the dropdown never holds a value without an item
    final saved = _aiModelName;
    if (saved != null && !items.any((i) => i.value == saved)) {
      items.add(
        DropdownMenuItem<String>(
          value: saved,
          child: Text(
            withKey.contains(_aiProvider)
                ? '$saved  ($_aiProvider)'
                : '$saved  (no API key)',
          ),
        ),
      );
    }
    return items;
  }

  Widget _aiSettingsSection() {
    return GroupingDecorator(
      decoratorKey: const Key('aiSettingsSection'),
      labelText: 'AI Settings',
      icon: Icons.psychology,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure LLM provider API keys (gemini, openai, anthropic, …). '
            'Only models of a provider with a key can be selected.',
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
              helperText:
                  'Model used for AI content generation across this tenant.',
            ),
            items: _modelItems(),
            onChanged: (v) => setState(() {
              _aiModelName = v;
              _aiProvider = v == null
                  ? ''
                  : llmModels
                        .firstWhere(
                          (m) => m.modelId == v,
                          orElse: () => LlmModel(providerForModel(v), v),
                        )
                        .provider;
            }),
          ),
          SizedBox(height: 16),
          ..._llmRows.asMap().entries.map((e) => _llmProviderRow(e.key)),
          SizedBox(height: 8),
          TextButton.icon(
            key: const Key('addLlmProvider'),
            icon: const Icon(Icons.add),
            label: Text(CoreLocalizations.of(context)!.addProvider),
            onPressed: () => setState(() {
              _llmRows.add({
                'providerCtrl': TextEditingController(text: llmProviders.first),
                'apiKeyCtrl': TextEditingController(),
                'obscure': true,
                'apiKeyIsSet': false,
              });
            }),
          ),
          SizedBox(height: 16),
          _tokenLimitField(),
        ],
      ),
    );
  }

  /// Monthly token limit. Read-only while this tenant generates on the GrowERP
  /// system key (the allowance is support's to set), editable as the tenant's
  /// own cap once the selected model runs on the tenant's own API key.
  Widget _tokenLimitField() {
    final localizations = CoreLocalizations.of(context)!;
    final own = _hasOwnKeyForSelectedModel;
    final systemLimit = _systemTokenLimit ?? 0;
    return TextFormField(
      key: const Key('llmMonthlyTokenLimit'),
      controller: own ? _ownTokenLimitCtrl : _systemTokenLimitCtrl,
      enabled: own,
      decoration: InputDecoration(
        labelText: localizations.monthlyTokenLimit,
        hintText: own ? 'e.g. 100000' : '',
        helperMaxLines: 3,
        helperText: own
            ? localizations.ownTokenLimitHelp(_tokensUsed)
            : localizations.systemTokenLimitHelp(
                _tokensUsed,
                systemLimit > 0 ? '$systemLimit' : '∞',
              ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (!own || value == null || value.isEmpty) return null;
        final number = int.tryParse(value);
        if (number == null || number < 0) {
          return localizations.enterAPositiveNumberOrLeaveEmpty;
        }
        return null;
      },
    );
  }

  Widget _llmProviderRow(int index) {
    final row = _llmRows[index];
    final providerCtrl = row['providerCtrl'] as TextEditingController;
    final apiKeyCtrl = row['apiKeyCtrl'] as TextEditingController;
    final obscure = row['obscure'] as bool;
    // a row loaded with a provider we do not know about keeps its value rather
    // than being silently rewritten to another provider
    final providers = [
      ...llmProviders,
      if (providerCtrl.text.isNotEmpty &&
          !llmProviders.contains(providerCtrl.text))
        providerCtrl.text,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: DropdownButtonFormField<String>(
              key: Key('llmProvider_$index'),
              initialValue: providerCtrl.text.isEmpty ? null : providerCtrl.text,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: providers
                  .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                  .toList(),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              onChanged: (v) => setState(() => providerCtrl.text = v ?? ''),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: Key('llmApiKey_$index'),
              controller: apiKeyCtrl,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'API Key',
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => row['obscure'] = !obscure),
                ),
              ),
            ),
          ),
          IconButton(
            key: Key('removeLlmProvider_$index'),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
            onPressed: () => setState(() {
              providerCtrl.dispose();
              apiKeyCtrl.dispose();
              _llmRows.removeAt(index);
            }),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        key: const Key('saveAiSettings'),
        icon: _isSaving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save AI Settings'),
        onPressed: _isSaving ? null : _saveSettings,
      ),
    );
  }
}
