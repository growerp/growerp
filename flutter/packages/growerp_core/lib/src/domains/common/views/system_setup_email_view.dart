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

import 'package:growerp_core/growerp_core.dart';

/// Email tab of System Setup: the tenant's own mail server, the same fields as
/// EmailSettingsDialog on the ADK Tools & integrations screen.
///
/// Saves only the email slice: update#SystemSettings leaves the fields it is
/// not sent alone, so the AI settings of the neighbouring tab are untouched.
class SystemSetupEmailView extends StatefulWidget {
  /// Called after a successful save, used by [SystemSetupDialog] to pop when it
  /// is shown modally.
  final VoidCallback? onSaved;

  /// False when embedded next to another section, which then draws the outer
  /// scroll view and padding.
  final bool standalone;

  const SystemSetupEmailView({super.key, this.onSaved, this.standalone = true});

  @override
  State<SystemSetupEmailView> createState() => _SystemSetupEmailViewState();
}

class _SystemSetupEmailViewState extends State<SystemSetupEmailView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

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
      _loadSettings();
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

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final s = await _restClient!.getSystemSettings();
      if (!mounted) return;

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
      // The smtp/store fields are sent together: they describe one mail server,
      // and a half sent one cannot connect. Secrets kept as '****' are skipped
      // backend-side.
      final pass = _mailPassCtrl.text;
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
      };
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
          _emailSettingsSection(),
          const SizedBox(height: 24),
          Center(child: _saveButton()),
        ],
      ),
    );
    if (!widget.standalone) return form;

    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return SingleChildScrollView(
      key: const Key('SystemSetupEmailView'),
      padding: EdgeInsets.all(isPhone ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isPhone ? 600 : 1000),
          child: form,
        ),
      ),
    );
  }

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
          Row(
            children: [
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
            ],
          ),
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
                value: 'starttls',
                child: Text(localizations.starttls),
              ),
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
                icon: Icon(
                  _obscureMailPass ? Icons.visibility : Icons.visibility_off,
                ),
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
          Row(
            children: [
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
            ],
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('storeProtocol'),
            initialValue: _storeProtocol,
            decoration: const InputDecoration(labelText: 'Protocol'),
            items: [
              DropdownMenuItem(
                value: 'imaps',
                child: Text(localizations.imapsSecure),
              ),
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

  Widget _saveButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        key: const Key('saveEmailSettings'),
        icon: _isSaving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Email Settings'),
        onPressed: _isSaving ? null : _saveSettings,
      ),
    );
  }
}
