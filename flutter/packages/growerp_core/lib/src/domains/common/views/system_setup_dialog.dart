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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../functions/functions.dart';

/// System Setup Screen — configures AI (Gemini API key) and email server settings.
/// Settings are stored per-tenant in the backend via the SystemSettings REST endpoint.
class SystemSetupDialog extends StatefulWidget {
  const SystemSetupDialog({super.key});

  /// Backward-compat: returns Gemini API key.
  /// Tries backend first (requires authenticated RestClient), falls back to SharedPreferences.
  static Future<String?> getGeminiApiKey(RestClient? restClient) async {
    if (restClient != null) {
      try {
        final s = await restClient.getSystemSettings();
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

  // AI
  final _geminiKeyCtrl = TextEditingController();
  bool _obscureGeminiKey = true;

  // SMTP
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController();
  String _smtpSecurity = 'none'; // none | starttls | ssl

  // Credentials
  final _mailUserCtrl = TextEditingController();
  final _mailPassCtrl = TextEditingController();
  bool _obscureMailPass = true;
  bool _mailPassSet = false; // true when backend already has a password

  // IMAP / store
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
    _geminiKeyCtrl.dispose();
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

      // One-time migration: lift gemini key from SharedPreferences to backend
      String geminiKey = s.geminiApiKey ?? '';
      if (geminiKey.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final local = prefs.getString('gemini_api_key');
        if (local != null && local.isNotEmpty) {
          geminiKey = local;
          // Will be saved to backend on next save; clear local copy now
          await prefs.remove('gemini_api_key');
        }
      }

      _geminiKeyCtrl.text = geminiKey;
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
      _storeFolderCtrl.text =
          (s.storeFolder.isNotEmpty) ? s.storeFolder : 'INBOX';
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
      final pass = _mailPassCtrl.text;
      final payload = {
        'geminiApiKey': _geminiKeyCtrl.text,
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
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'System Setup',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure AI and email server settings for your organisation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _aiSettingsSection(),
                const SizedBox(height: 24),
                _emailSettingsSection(),
                const SizedBox(height: 32),
                Center(child: _saveButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AI settings ─────────────────────────────────────────────────────────────

  Widget _aiSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.psychology, 'AI Settings'),
            const Divider(),
            Text(
              'Enter your Google Gemini API key to enable AI-powered navigation.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('geminiApiKey'),
              controller: _geminiKeyCtrl,
              obscureText: _obscureGeminiKey,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'Enter your API key',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscureGeminiKey
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscureGeminiKey = !_obscureGeminiKey),
                      tooltip: _obscureGeminiKey ? 'Show key' : 'Hide key',
                    ),
                    if (_geminiKeyCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _geminiKeyCtrl.clear()),
                        tooltip: 'Clear',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Get API Key from Google AI Studio'),
              onPressed: () => HelperFunctions.showMessage(
                context,
                'Visit: https://aistudio.google.com/apikey',
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Email server settings ────────────────────────────────────────────────────

  Widget _emailSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.email_outlined, 'Email Server'),
            const Divider(),
            Text(
              'Configure outgoing (SMTP) and incoming (IMAP/POP3) email for your organisation.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),

            // SMTP
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
                  decoration: const InputDecoration(labelText: 'Port'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('smtpSecurity'),
              value: _smtpSecurity,
              decoration: const InputDecoration(labelText: 'Security'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'starttls', child: Text('STARTTLS')),
                DropdownMenuItem(value: 'ssl', child: Text('SSL/TLS')),
              ],
              onChanged: (v) => setState(() => _smtpSecurity = v ?? 'none'),
            ),

            const SizedBox(height: 20),

            // Credentials
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
                if (_mailPassCtrl.text == '****') {
                  _mailPassCtrl.clear();
                }
              },
            ),

            const SizedBox(height: 20),

            // IMAP / store
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
                  decoration: const InputDecoration(labelText: 'Port'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('storeProtocol'),
              value: _storeProtocol,
              decoration: const InputDecoration(labelText: 'Protocol'),
              items: const [
                DropdownMenuItem(value: 'imaps', child: Text('IMAPS (secure)')),
                DropdownMenuItem(value: 'imap', child: Text('IMAP')),
                DropdownMenuItem(value: 'pop3', child: Text('POP3')),
              ],
              onChanged: (v) => setState(() => _storeProtocol = v ?? 'imaps'),
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
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        key: const Key('saveSettings'),
        icon: _isSaving
            ? const SizedBox(
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
