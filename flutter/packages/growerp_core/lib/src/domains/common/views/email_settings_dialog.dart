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

/// Edits the tenant's email server (SMTP + credentials + IMAP/store).
/// Read-modify-write: loads the full [SystemSettings] and resends a complete
/// payload so the default-valued store/smtp params on update#SystemSettings do
/// not clobber other fields. Backend syncs SMTP/store into
/// moqui.basic.email.EmailServer so core ERP email keeps working.
/// Returns true when settings were saved.
class EmailSettingsDialog extends StatefulWidget {
  const EmailSettingsDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => const EmailSettingsDialog(),
      );

  @override
  State<EmailSettingsDialog> createState() => _EmailSettingsDialogState();
}

class _EmailSettingsDialogState extends State<EmailSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // The full settings as last loaded, so we can preserve non-email fields.
  SystemSettings? _settings;

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
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    _mailUserCtrl.dispose();
    _mailPassCtrl.dispose();
    _storeHostCtrl.dispose();
    _storePortCtrl.dispose();
    _storeFolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
      final pass = _mailPassCtrl.text;
      // Read-modify-write: send the full settings, overriding the email slice and
      // preserving everything else (github fields). llmConfigs is omitted so LLM
      // keys are never touched. Secrets returned as '****' are skipped backend-side.
      final payload = <String, dynamic>{
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
        // preserve github fields untouched
        'githubRepository': s?.githubRepository ?? '',
      };
      await _restClient!.updateSystemSettings(payload);
      if (mounted) {
        HelperFunctions.showMessage(
            context, 'Email settings saved', Colors.green);
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
      key: const Key('EmailSettingsDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Email Server',
        width: 500,
        height: 640,
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
                            Text('Outgoing (SMTP)',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
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
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  key: const Key('smtpPort'),
                                  controller: _smtpPortCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Port'),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: const Key('smtpSecurity'),
                              initialValue: _smtpSecurity,
                              decoration:
                                  const InputDecoration(labelText: 'Security'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'none', child: Text('None')),
                                DropdownMenuItem(
                                    value: 'starttls', child: Text('STARTTLS')),
                                DropdownMenuItem(
                                    value: 'ssl', child: Text('SSL/TLS')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _smtpSecurity = v ?? 'none'),
                            ),
                            const SizedBox(height: 20),
                            Text('Credentials',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: const Key('mailUsername'),
                              controller: _mailUserCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Username / Email',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('mailPassword'),
                              controller: _mailPassCtrl,
                              obscureText: _obscureMailPass,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: _mailPassSet
                                    ? '(leave as **** to keep current)'
                                    : '',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureMailPass
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() =>
                                      _obscureMailPass = !_obscureMailPass),
                                ),
                              ),
                              onTap: () {
                                if (_mailPassCtrl.text == '****') {
                                  _mailPassCtrl.clear();
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            Text('Incoming (IMAP / POP3)',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
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
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  key: const Key('storePort'),
                                  controller: _storePortCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      const InputDecoration(labelText: 'Port'),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: const Key('storeProtocol'),
                              initialValue: _storeProtocol,
                              decoration:
                                  const InputDecoration(labelText: 'Protocol'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'imaps',
                                    child: Text('IMAPS (secure)')),
                                DropdownMenuItem(
                                    value: 'imap', child: Text('IMAP')),
                                DropdownMenuItem(
                                    value: 'pop3', child: Text('POP3')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _storeProtocol = v ?? 'imaps'),
                            ),
                            const SizedBox(height: 12),
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: const Key('cancelEmailSettings'),
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('saveEmailSettings'),
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
