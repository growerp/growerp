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

/// Edits the tenant's Google Workspace OAuth credentials (client id/secret,
/// refresh token, calendar id) used by the Google Calendar booking capture:
/// Meet bookings are imported as lead activities and Gemini meeting notes are
/// attached afterwards. Read-modify-write like [GithubSettingsDialog]: resends
/// the email/store slice so default-valued params don't clobber stored config.
/// Returns true when settings were saved.
class GoogleWorkspaceSettingsDialog extends StatefulWidget {
  const GoogleWorkspaceSettingsDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => const GoogleWorkspaceSettingsDialog(),
      );

  @override
  State<GoogleWorkspaceSettingsDialog> createState() =>
      _GoogleWorkspaceSettingsDialogState();
}

class _GoogleWorkspaceSettingsDialogState
    extends State<GoogleWorkspaceSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  SystemSettings? _settings;

  final _clientIdCtrl = TextEditingController();
  final _clientSecretCtrl = TextEditingController();
  bool _obscureClientSecret = true;
  bool _clientSecretSet = false;
  final _refreshTokenCtrl = TextEditingController();
  bool _obscureRefreshToken = true;
  bool _refreshTokenSet = false;
  final _calendarIdCtrl = TextEditingController();

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
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _refreshTokenCtrl.dispose();
    _calendarIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final s = await _restClient!.getSystemSettings();
      if (!mounted) return;
      _settings = s;
      _clientIdCtrl.text = s.googleClientId ?? '';
      _clientSecretSet = (s.googleClientSecret ?? '').isNotEmpty;
      _clientSecretCtrl.text = _clientSecretSet ? '****' : '';
      _refreshTokenSet = (s.googleRefreshToken ?? '').isNotEmpty;
      _refreshTokenCtrl.text = _refreshTokenSet ? '****' : '';
      _calendarIdCtrl.text = s.googleCalendarId ?? '';
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
      final secret = _clientSecretCtrl.text;
      final refreshToken = _refreshTokenCtrl.text;
      // Read-modify-write: preserve the email/store slice (its default-valued
      // params would otherwise be reset to defaults and clobber the stored email
      // config). Secrets returned as '****' are skipped backend-side.
      final payload = <String, dynamic>{
        'googleClientId': _clientIdCtrl.text,
        if (secret.isNotEmpty && secret != '****') 'googleClientSecret': secret,
        if (refreshToken.isNotEmpty && refreshToken != '****')
          'googleRefreshToken': refreshToken,
        'googleCalendarId': _calendarIdCtrl.text,
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
            context, 'Google Workspace settings saved', Colors.green);
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

  Widget _secretField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required bool isSet,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: isSet ? '(leave as **** to keep current)' : '',
        prefixIcon: const Icon(Icons.security),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleObscure,
        ),
      ),
      onTap: () {
        if (controller.text == '****') controller.clear();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('GoogleWorkspaceSettingsDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Google Workspace Settings',
        width: 500,
        height: 520,
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
                              'OAuth credentials (scopes: calendar.readonly, '
                              'drive.readonly) used to import Google Meet '
                              'bookings as lead activities and attach Gemini '
                              'meeting notes.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('googleClientId'),
                              controller: _clientIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'OAuth Client ID',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _secretField(
                              key: const Key('googleClientSecret'),
                              controller: _clientSecretCtrl,
                              label: 'OAuth Client Secret',
                              isSet: _clientSecretSet,
                              obscure: _obscureClientSecret,
                              onToggleObscure: () => setState(() =>
                                  _obscureClientSecret = !_obscureClientSecret),
                            ),
                            const SizedBox(height: 12),
                            _secretField(
                              key: const Key('googleRefreshToken'),
                              controller: _refreshTokenCtrl,
                              label: 'OAuth Refresh Token',
                              isSet: _refreshTokenSet,
                              obscure: _obscureRefreshToken,
                              onToggleObscure: () => setState(() =>
                                  _obscureRefreshToken = !_obscureRefreshToken),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('googleCalendarId'),
                              controller: _calendarIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Calendar ID',
                                hintText: 'primary',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
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
                          key: const Key('cancelGoogleWorkspaceSettings'),
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('saveGoogleWorkspaceSettings'),
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
