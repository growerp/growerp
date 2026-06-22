/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../functions/functions.dart';
import '../widgets/widgets.dart';

/// Edits the tenant's GitHub token + repository (used by the ADK GithubTool).
/// Read-modify-write: loads the full [SystemSettings] and resends the complete
/// payload (preserving the email/store fields, whose default-valued params would
/// otherwise clobber the stored email config). llmConfigs is omitted so LLM keys
/// are never touched. Returns true when settings were saved.
class GithubSettingsDialog extends StatefulWidget {
  const GithubSettingsDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => const GithubSettingsDialog(),
      );

  @override
  State<GithubSettingsDialog> createState() => _GithubSettingsDialogState();
}

class _GithubSettingsDialogState extends State<GithubSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  SystemSettings? _settings;

  final _githubTokenCtrl = TextEditingController();
  bool _obscureGithubToken = true;
  bool _githubTokenSet = false;
  final _githubRepoCtrl = TextEditingController();

  RestClient? _restClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restClient = context.read<RestClient>();
      _load();
    });
  }

  @override
  void dispose() {
    _githubTokenCtrl.dispose();
    _githubRepoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final s = await _restClient!.getSystemSettings();
      if (!mounted) return;
      _settings = s;
      _githubTokenSet = (s.githubToken ?? '').isNotEmpty;
      _githubTokenCtrl.text = _githubTokenSet ? '****' : '';
      _githubRepoCtrl.text = s.githubRepository ?? '';
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
            context, 'Failed to load settings: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final s = _settings;
      final token = _githubTokenCtrl.text;
      // Read-modify-write: preserve the email/store slice (its default-valued
      // params would otherwise be reset to defaults and clobber the stored email
      // config). Secrets returned as '****' are skipped backend-side.
      final payload = <String, dynamic>{
        'githubRepository': _githubRepoCtrl.text,
        if (token.isNotEmpty && token != '****') 'githubToken': token,
        // preserve email/store fields untouched
        'smtpHost': s?.smtpHost ?? '',
        'smtpPort': s?.smtpPort ?? '',
        'smtpStartTls': s?.smtpStartTls ?? 'N',
        'smtpSsl': s?.smtpSsl ?? 'N',
        'mailUsername': s?.mailUsername ?? '',
        'storeHost': s?.storeHost ?? '',
        'storePort': s?.storePort ?? '',
        'storeProtocol': s?.storeProtocol ?? 'imaps',
        'storeFolder': s?.storeFolder ?? 'INBOX',
        'storeDelete': s?.storeDelete ?? 'N',
        'storeMarkSeen': s?.storeMarkSeen ?? 'Y',
        'storeSkipSeen': s?.storeSkipSeen ?? 'Y',
      };
      await _restClient!.updateSystemSettings(payload);
      if (mounted) {
        HelperFunctions.showMessage(
            context, 'GitHub settings saved', Colors.green);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
            context, 'Failed to save settings: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('GithubSettingsDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'GitHub Settings',
        width: 500,
        height: 360,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GitHub personal access token (GITHUB_TOKEN) and '
                              'default repository, used by the AI GitHub tool.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('githubToken'),
                              controller: _githubTokenCtrl,
                              obscureText: _obscureGithubToken,
                              decoration: InputDecoration(
                                labelText: 'GitHub Token (GITHUB_TOKEN)',
                                hintText: _githubTokenSet
                                    ? '(leave as **** to keep current)'
                                    : '',
                                prefixIcon: const Icon(Icons.security),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureGithubToken
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _obscureGithubToken =
                                          !_obscureGithubToken),
                                ),
                              ),
                              onTap: () {
                                if (_githubTokenCtrl.text == '****') {
                                  _githubTokenCtrl.clear();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('githubRepository'),
                              controller: _githubRepoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'GitHub Repository',
                                hintText: 'owner/repository',
                                prefixIcon: Icon(Icons.source_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: const Key('cancelGithubSettings'),
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('saveGithubSettings'),
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
