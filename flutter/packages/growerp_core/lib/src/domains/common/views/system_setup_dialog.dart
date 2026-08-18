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

/// System Setup Screen — configures AI (LLM provider API keys).
/// Settings are stored per-tenant in the backend via the SystemSettings REST endpoint.
/// Email and GitHub credentials are configured from the ADK Tools & integrations
/// screen (EmailSettingsDialog / GithubSettingsDialog).
class SystemSetupDialog extends StatefulWidget {
  /// When shown modally (e.g. from the ADK chat as a Dialog) rather than as a
  /// full-screen menu route: adds a Cancel button and pops on a successful save.
  final bool inDialog;
  const SystemSetupDialog({super.key, this.inDialog = false});

  /// Backward-compat: returns Gemini API key.
  /// Checks llmConfigs list first, then legacy geminiApiKey field, then SharedPreferences.
  static Future<String?> getGeminiApiKey(RestClient? restClient) async {
    if (restClient != null) {
      try {
        final s = await restClient.getSystemSettings();
        final geminiCfg = s.llmConfigs
            .where((lc) => lc.llmProvider == 'gemini')
            .firstOrNull;
        if (geminiCfg?.apiKey != null && geminiCfg!.apiKey!.isNotEmpty) {
          return geminiCfg.apiKey;
        }
        if (s.geminiApiKey != null && s.geminiApiKey!.isNotEmpty) {
          return s.geminiApiKey;
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key');
  }

  @override
  State<SystemSetupDialog> createState() => _SystemSetupDialogState();
}

class _SystemSetupDialogState extends State<SystemSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // AI — dynamic list of {providerCtrl, apiKeyCtrl, obscure, apiKeyIsSet}
  final List<Map<String, dynamic>> _llmRows = [];
  static const _geminiModels = [
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];
  String? _aiModelName;

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
          .map((lc) => <String, dynamic>{
                'providerCtrl': TextEditingController(text: lc.llmProvider),
                'apiKeyCtrl':
                    TextEditingController(text: lc.apiKey ?? ''),
                'obscure': true,
                'apiKeyIsSet': (lc.apiKey ?? '').isNotEmpty,
              })
          .toList();

      // Dispose old rows before replacing
      for (final row in _llmRows) {
        (row['providerCtrl'] as TextEditingController).dispose();
        (row['apiKeyCtrl'] as TextEditingController).dispose();
      }
      _llmRows
        ..clear()
        ..addAll(newRows);
      _aiModelName =
          _geminiModels.contains(s.aiModelName) ? s.aiModelName : null;
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
          .where((r) =>
              (r['providerCtrl'] as TextEditingController).text.isNotEmpty)
          .map((r) {
            final provider =
                (r['providerCtrl'] as TextEditingController).text;
            final apiKey = (r['apiKeyCtrl'] as TextEditingController).text;
            final m = <String, dynamic>{'llmProvider': provider};
            if (apiKey.isNotEmpty && apiKey != '****') m['apiKey'] = apiKey;
            return m;
          })
          .toList();
      // Only LLM keys are managed here. Email/GitHub credentials live in the ADK
      // Tools & integrations screen; omitting them leaves those fields unchanged.
      final payload = <String, dynamic>{'llmConfigs': llmConfigs};
      payload['aiModelName'] = _aiModelName ?? '';
      await _restClient!.updateSystemSettings(payload);
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Settings saved successfully',
          Theme.of(context).colorScheme.primary,
        );
        // When opened as a modal dialog (e.g. from the ADK chat), close on save
        // so the user returns to where they were and can retry.
        if (widget.inDialog) Navigator.of(context).pop();
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

    final isPhone = ResponsiveBreakpoints.of(context).isMobile;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      key: const Key('SystemSetupDialog'),
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
                  'AI Settings',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  CoreLocalizations.of(context)!.configureLlmProviderApiKeys,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                _aiSettingsSection(),
                SizedBox(height: 32),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.inDialog) ...[
                        OutlinedButton(
                          key: const Key('cancelSettings'),
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(CoreLocalizations.of(context)!.cancel),
                        ),
                        SizedBox(width: 16),
                      ],
                      _saveButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AI settings ─────────────────────────────────────────────────────────────

  Widget _aiSettingsSection() {
    return GroupingDecorator(
      decoratorKey: const Key('aiSettingsSection'),
      labelText: 'AI Settings',
      icon: Icons.psychology,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure LLM provider API keys (gemini, openai, anthropic, …).',
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
              helperText: 'Gemini model used for AI content generation across this tenant.',
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(CoreLocalizations.of(context)!.systemDefault),
              ),
              ..._geminiModels.map(
                (m) => DropdownMenuItem<String>(value: m, child: Text(m)),
              ),
            ],
            onChanged: (v) => setState(() => _aiModelName = v),
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
                'providerCtrl': TextEditingController(),
                'apiKeyCtrl': TextEditingController(),
                'obscure': true,
                'apiKeyIsSet': false,
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _llmProviderRow(int index) {
    final row = _llmRows[index];
    final providerCtrl = row['providerCtrl'] as TextEditingController;
    final apiKeyCtrl = row['apiKeyCtrl'] as TextEditingController;
    final obscure = row['obscure'] as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: TextFormField(
              key: Key('llmProvider_$index'),
              controller: providerCtrl,
              decoration: const InputDecoration(
                labelText: 'Provider',
                hintText: 'gemini',
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
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
                  icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => row['obscure'] = !obscure),
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
        key: const Key('saveSettings'),
        icon: _isSaving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
        onPressed: _isSaving ? null : _saveSettings,
      ),
    );
  }
}
