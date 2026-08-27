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

/// System Setup Screen — configures AI (LLM provider API keys) and the email
/// server (SMTP/IMAP), the same email fields as EmailSettingsDialog on the ADK
/// Tools & integrations screen.
/// Settings are stored per-tenant in the backend via the SystemSettings REST endpoint.
/// GitHub credentials are configured from the ADK Tools & integrations screen
/// (GithubSettingsDialog).
/// Widget name of the outreach setup guide screen in the app menu.
const String _guideWidgetName = 'OutreachSetupGuideScreen';

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
  String? _aiModelName;
  String _aiProvider = '';
  /// The tenant's own monthly cap, editable only while running on an own key.
  final _ownTokenLimitCtrl = TextEditingController();
  /// Read-only: free allowance in effect and what was used of it this month.
  final _systemTokenLimitCtrl = TextEditingController();
  int? _systemTokenLimit;
  int _tokensUsed = 0;

  // Email — same fields as EmailSettingsDialog (ADK Tools & integrations),
  // shown here too because this is the screen the outreach setup guide sends
  // people to for the email server.
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController();
  String _smtpSecurity = 'none'; // none | starttls | ssl
  final _mailUserCtrl = TextEditingController();
  final _mailPassCtrl = TextEditingController();
  bool _obscureMailPass = true;
  bool _mailPassSet = false;
  final _storeHostCtrl = TextEditingController();
  final _storePortCtrl = TextEditingController();
  String _storeProtocol = 'imaps';
  final _storeFolderCtrl = TextEditingController();

  /// Settings as last loaded, to preserve the fields not edited here.
  SystemSettings? _settings;

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
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    _mailUserCtrl.dispose();
    _mailPassCtrl.dispose();
    _storeHostCtrl.dispose();
    _storePortCtrl.dispose();
    _storeFolderCtrl.dispose();
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
      _settings = s;

      _smtpHostCtrl.text = s.smtpHost ?? '';
      _smtpPortCtrl.text = s.smtpPort ?? '';
      _smtpSecurity = s.smtpSsl == 'Y'
          ? 'ssl'
          : s.smtpStartTls == 'Y'
              ? 'starttls'
              : 'none';
      _mailUserCtrl.text = s.mailUsername ?? '';
      _mailPassSet = (s.mailPassword ?? '').isNotEmpty;
      _mailPassCtrl.text = _mailPassSet ? '****' : '';
      _storeHostCtrl.text = s.storeHost ?? '';
      _storePortCtrl.text = s.storePort ?? '';
      _storeProtocol = s.storeProtocol.isNotEmpty ? s.storeProtocol : 'imaps';
      _storeFolderCtrl.text = s.storeFolder.isNotEmpty ? s.storeFolder : 'INBOX';

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
      _systemTokenLimitCtrl.text =
          (s.systemTokenLimit ?? 0) > 0 ? s.systemTokenLimit.toString() : '';
      _tokensUsed = s.tokensUsedThisMonth ?? 0;
      _ownTokenLimitCtrl.text =
          (s.ownTokenLimit ?? 0) > 0 ? s.ownTokenLimit.toString() : '';
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
      // Read-modify-write for the email slice: update#SystemSettings has
      // default-valued smtp/store params, so they must be sent together, with
      // the github fields preserved. Secrets kept as '****' are skipped
      // backend-side.
      final pass = _mailPassCtrl.text;
      final payload = <String, dynamic>{'llmConfigs': llmConfigs};
      payload['aiModelName'] = _selectedModelId();
      payload['aiProvider'] = _selectedModelId().isEmpty ? '' : _aiProvider;
      // only meaningful on an own key; 0 clears the cap. Not sent otherwise, so
      // switching back to the system default never leaves a stale cap behind.
      if (_hasOwnKeyForSelectedModel) {
        payload['ownTokenLimit'] =
            int.tryParse(_ownTokenLimitCtrl.text.trim()) ?? 0;
      }
      payload.addAll({
        'smtpHost': _smtpHostCtrl.text,
        'smtpPort': _smtpPortCtrl.text,
        'smtpStartTls': _smtpSecurity == 'starttls' ? 'Y' : 'N',
        'smtpSsl': _smtpSecurity == 'ssl' ? 'Y' : 'N',
        'mailUsername': _mailUserCtrl.text,
        if (pass.isNotEmpty && pass != '****') 'mailPassword': pass,
        'storeHost': _storeHostCtrl.text,
        'storePort': _storePortCtrl.text,
        'storeProtocol': _storeProtocol,
        'storeFolder': _storeFolderCtrl.text,
        'githubRepository': _settings?.githubRepository ?? '',
      });
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

  /// Menu item of the outreach setup guide, when the running app has one and
  /// a [MenuConfigBloc] is available. Used for the show/hide switch below.
  MenuItem? _guideMenuItem(BuildContext context) {
    MenuConfiguration? config;
    try {
      config = context.watch<MenuConfigBloc>().state.menuConfiguration;
    } catch (_) {
      return null;
    }
    for (final item in config?.menuItems ?? <MenuItem>[]) {
      if (item.widgetName == _guideWidgetName) return item;
      for (final child in item.children ?? <MenuItem>[]) {
        if (child.widgetName == _guideWidgetName) return child;
      }
    }
    return null;
  }

  /// Switch showing the outreach setup guide in the menu, per user. Applies
  /// immediately, it is not part of the save below.
  Widget _outreachGuideSection(MenuItem guideItem) {
    final localizations = CoreLocalizations.of(context)!;
    return GroupingDecorator(
      decoratorKey: const Key('outreachGuideSection'),
      labelText: 'Outreach Guide',
      icon: Icons.checklist,
      child: SwitchListTile(
        key: const Key('showOutreachGuide'),
        contentPadding: EdgeInsets.zero,
        title: Text(localizations.showOutreachGuide),
        subtitle: Text(localizations.showOutreachGuideHelp),
        value: guideItem.isActive,
        onChanged: (value) => context.read<MenuConfigBloc>().add(
          MenuWidgetVisibilitySet(
            widgetName: _guideWidgetName,
            hidden: !value,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    final guideItem = _guideMenuItem(context);

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
                  'System Settings',
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
                SizedBox(height: 24),
                _emailSettingsSection(),
                if (guideItem?.menuItemId != null) ...[
                  SizedBox(height: 24),
                  _outreachGuideSection(guideItem!),
                ],
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

  // ── Email settings ──────────────────────────────────────────────────────────

  Widget _emailSettingsSection() {
    final localizations = CoreLocalizations.of(context)!;
    return GroupingDecorator(
      decoratorKey: const Key('emailSettingsSection'),
      labelText: 'Email Server',
      icon: Icons.mail_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.outgoingSmtp,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                key: const Key('smtpHost'),
                controller: _smtpHostCtrl,
                decoration: const InputDecoration(
                  labelText: 'SMTP Host',
                  hintText: 'smtp.example.com',
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const Key('smtpPort'),
                controller: _smtpPortCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
                // port and security must match: sending plaintext into 465
                // just times out
                validator: (value) {
                  final port = value?.trim() ?? '';
                  if (port == '465' && _smtpSecurity != 'ssl') {
                    return 'Port 465 needs SSL/TLS';
                  }
                  if (port == '587' && _smtpSecurity == 'ssl') {
                    return 'Port 587 needs STARTTLS';
                  }
                  return null;
                },
              ),
            ),
          ]),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('smtpSecurity'),
            initialValue: _smtpSecurity,
            decoration: const InputDecoration(
              labelText: 'Security',
              helperText: '465: SSL/TLS, 587: STARTTLS',
            ),
            items: [
              DropdownMenuItem(value: 'none', child: Text(localizations.none)),
              DropdownMenuItem(
                  value: 'starttls', child: Text(localizations.starttls)),
              DropdownMenuItem(value: 'ssl', child: Text(localizations.ssltls)),
            ],
            onChanged: (v) {
              setState(() => _smtpSecurity = v ?? 'none');
              _formKey.currentState?.validate();
            },
          ),
          SizedBox(height: 20),
          Text(
            localizations.credentials,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 8),
          TextFormField(
            key: const Key('mailUsername'),
            controller: _mailUserCtrl,
            decoration: const InputDecoration(
              labelText: 'Username / Email',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          SizedBox(height: 12),
          TextFormField(
            key: const Key('mailPassword'),
            controller: _mailPassCtrl,
            obscureText: _obscureMailPass,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: _mailPassSet ? '(leave as **** to keep current)' : '',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureMailPass
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscureMailPass = !_obscureMailPass),
              ),
            ),
            onTap: () {
              if (_mailPassCtrl.text == '****') _mailPassCtrl.clear();
            },
          ),
          SizedBox(height: 20),
          Text(
            localizations.incomingImapPop3,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                key: const Key('storeHost'),
                controller: _storeHostCtrl,
                decoration: const InputDecoration(
                  labelText: 'IMAP Host',
                  hintText: 'imap.example.com',
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const Key('storePort'),
                controller: _storePortCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Port'),
              ),
            ),
          ]),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('storeProtocol'),
            initialValue: _storeProtocol,
            decoration: const InputDecoration(labelText: 'Protocol'),
            items: [
              DropdownMenuItem(
                  value: 'imaps', child: Text(localizations.imapsSecure)),
              DropdownMenuItem(value: 'imap', child: Text(localizations.imap)),
              DropdownMenuItem(value: 'pop3', child: Text(localizations.pop3)),
            ],
            onChanged: (v) => setState(() => _storeProtocol = v ?? 'imaps'),
          ),
          SizedBox(height: 12),
          TextFormField(
            key: const Key('storeFolder'),
            controller: _storeFolderCtrl,
            decoration: const InputDecoration(
              labelText: 'Folder',
              hintText: 'INBOX',
            ),
          ),
        ],
      ),
    );
  }

  // ── AI settings ─────────────────────────────────────────────────────────────

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
      .where((r) =>
          (r['apiKeyCtrl'] as TextEditingController).text.trim().isNotEmpty ||
          r['apiKeyIsSet'] == true)
      .map((r) => (r['providerCtrl'] as TextEditingController).text.trim())
      .where((p) => p.isNotEmpty)
      .toSet();

  /// True when the selected model runs on this tenant's own API key: only then
  /// is the monthly token limit the tenant's own cap rather than the free
  /// allowance set by GrowERP support.
  bool get _hasOwnKeyForSelectedModel {
    final model = _aiModelName;
    if (model == null) return false;
    final provider =
        _aiProvider.isNotEmpty ? _aiProvider : providerForModel(model);
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
      items.add(DropdownMenuItem<String>(
        value: model.modelId,
        child: Text('${model.modelId}  (${model.provider})'),
      ));
    }
    // a saved model whose key row was removed, or one no longer in the shared
    // list, stays selectable: opening this screen never silently rewrites the
    // stored setting, and the dropdown never holds a value without an item
    final saved = _aiModelName;
    if (saved != null && !items.any((i) => i.value == saved)) {
      items.add(DropdownMenuItem<String>(
        value: saved,
        child: Text(withKey.contains(_aiProvider)
            ? '$saved  ($_aiProvider)'
            : '$saved  (no API key)'),
      ));
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
                      .firstWhere((m) => m.modelId == v,
                          orElse: () => LlmModel(providerForModel(v), v))
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
                _tokensUsed, systemLimit > 0 ? '$systemLimit' : '\u221e'),
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
      if (providerCtrl.text.isNotEmpty && !llmProviders.contains(providerCtrl.text))
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
              initialValue:
                  providerCtrl.text.isEmpty ? null : providerCtrl.text,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: providers
                  .map((p) =>
                      DropdownMenuItem<String>(value: p, child: Text(p)))
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
