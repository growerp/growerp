import 'dart:async';
import 'dart:convert';

import 'package:growerp_core/growerp_core.dart';
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

/// Connects the tenant's Google Workspace: Drive (Gemini meeting notes), Gmail
/// (mail server with OAuth2) and Calendar (Meet bookings imported as lead
/// activities). Each service has a Sign in button that opens the Google
/// consent page in the browser; the backend callback stores the refresh token
/// and this dialog polls the settings until the service shows as connected.
/// Tenants with their own OAuth client keep the client id/secret/refresh token
/// fields under "Use your own OAuth client".
/// Returns true when anything was connected, disconnected or saved.
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

/// Scope per service, same as SERVICE_SCOPES in GoogleWorkspaceUtil.groovy.
const _serviceScopes = {
  'drive': 'https://www.googleapis.com/auth/drive.readonly',
  'gmail': 'https://mail.google.com/',
  'calendar': 'https://www.googleapis.com/auth/calendar.readonly',
};

class _GoogleWorkspaceSettingsDialogState
    extends State<GoogleWorkspaceSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _changed = false;

  SystemSettings? _settings;

  // services waiting for the Google sign in to complete, polled until granted
  List<String>? _waitingFor;
  Timer? _pollTimer;
  int _pollRequestId = 0;
  DateTime? _waitUntil;

  final _clientIdCtrl = TextEditingController();
  final _clientSecretCtrl = TextEditingController();
  bool _obscureClientSecret = true;
  bool _clientSecretSet = false;
  final _refreshTokenCtrl = TextEditingController();
  bool _obscureRefreshToken = true;
  bool _refreshTokenSet = false;
  final _calendarIdCtrl = TextEditingController();
  final _bookingUrlCtrl = TextEditingController();

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
    _pollTimer?.cancel();
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _refreshTokenCtrl.dispose();
    _calendarIdCtrl.dispose();
    _bookingUrlCtrl.dispose();
    super.dispose();
  }

  void _apply(SystemSettings s) {
    _settings = s;
    _clientIdCtrl.text = s.googleClientId ?? '';
    _clientSecretSet = (s.googleClientSecret ?? '').isNotEmpty;
    _clientSecretCtrl.text = _clientSecretSet ? '****' : '';
    _refreshTokenSet = (s.googleRefreshToken ?? '').isNotEmpty;
    _refreshTokenCtrl.text = _refreshTokenSet ? '****' : '';
    _calendarIdCtrl.text = s.googleCalendarId ?? '';
    _bookingUrlCtrl.text = s.googleBookingUrl ?? '';
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final s = await _restClient!.getSystemSettings();
      if (!mounted) return;
      _apply(s);
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to load settings: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _connected(String service) => (_settings?.googleGrantedScopes ?? '')
      .split(' ')
      .contains(_serviceScopes[service]);

  bool get _signInAvailable => _settings?.googleOAuthAvailable == true;

  // configured the old way: own client with a pasted refresh token
  bool get _ownClient => (_settings?.googleClientId ?? '').isNotEmpty;

  Future<void> _signIn(List<String> services) async {
    try {
      final result = await _restClient!.startGoogleSignIn(services: services);
      final map = result is String ? jsonDecode(result) : result;
      final authUrl = map['authUrl'] as String?;
      if (authUrl == null || authUrl.isEmpty) throw 'no sign in url';
      if (!await openExternalUrl(Uri.parse(authUrl))) {
        throw 'could not open the browser';
      }
      if (!mounted) return;
      setState(() {
        _waitingFor = services;
        _waitUntil = DateTime.now().add(const Duration(minutes: 3));
      });
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Google sign in failed: $e',
          Colors.red,
        );
      }
    }
  }

  Future<void> _poll() async {
    final requestId = ++_pollRequestId;
    if (_waitUntil != null && DateTime.now().isAfter(_waitUntil!)) {
      _stopWaiting();
      return;
    }
    try {
      final s = await _restClient!.getSystemSettings();
      if (!mounted || requestId != _pollRequestId || _waitingFor == null) {
        return;
      }
      final waitingFor = _waitingFor!;
      setState(() => _apply(s));
      if (waitingFor.every(_connected)) {
        _changed = true;
        _stopWaiting();
        HelperFunctions.showMessage(
          context,
          'Google Workspace connected',
          Colors.green,
        );
      }
    } catch (_) {
      // try again on the next tick
    }
  }

  void _stopWaiting() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollRequestId++;
    if (mounted) setState(() => _waitingFor = null);
  }

  Future<void> _disconnect(String service) async {
    try {
      final s = await _restClient!.disconnectGoogleService(service: service);
      if (!mounted) return;
      _changed = true;
      setState(() => _apply(s));
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to disconnect: $e',
          Colors.red,
        );
      }
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
        'googleBookingUrl': _bookingUrlCtrl.text.trim(),
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
          context,
          'Google Workspace settings saved',
          Colors.green,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to save settings: $e',
          Colors.red,
        );
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

  /// One service card: icon, name, description and Sign in / Disconnect.
  Widget _serviceCard({
    required String service,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    List<String>? signInServices,
    String signInLabel = 'Sign in',
  }) {
    final colors = Theme.of(context).colorScheme;
    final services = signInServices ?? [service];
    final connected = services.every(_connected);
    final waiting =
        _waitingFor != null &&
        _waitingFor!.length == services.length &&
        _waitingFor!.every(services.contains);
    Widget action;
    if (waiting) {
      action = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (connected && signInServices == null) {
      action = OutlinedButton(
        key: Key('googleDisconnect_$service'),
        onPressed: () => _disconnect(service),
        child: const Text('Disconnect'),
      );
    } else if (connected) {
      action = Chip(
        key: Key('googleConnected_$service'),
        avatar: Icon(Icons.check_circle, color: Colors.green.shade600),
        label: const Text('Connected'),
      );
    } else {
      action = FilledButton.tonal(
        key: Key(
          signInServices == null ? 'googleSignIn_$service' : 'googleConnectAll',
        ),
        onPressed: _signInAvailable && _waitingFor == null
            ? () => _signIn(services)
            : null,
        child: Text(signInLabel),
      );
    }
    return Card(
      key: Key('googleCard_$service'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    connected && signInServices == null
                        ? 'Connected${(_settings?.googleAccountEmail ?? '').isNotEmpty ? ' as ${_settings!.googleAccountEmail}' : ''}'
                        : description,
                    style: TextStyle(fontSize: 13, color: colors.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            action,
          ],
        ),
      ),
    );
  }

  Widget _ownClientFields() {
    return Column(
      children: [
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
          onToggleObscure: () =>
              setState(() => _obscureClientSecret = !_obscureClientSecret),
        ),
        const SizedBox(height: 12),
        _secretField(
          key: const Key('googleRefreshToken'),
          controller: _refreshTokenCtrl,
          label: 'OAuth Refresh Token',
          isSet: _refreshTokenSet,
          obscure: _obscureRefreshToken,
          onToggleObscure: () =>
              setState(() => _obscureRefreshToken = !_obscureRefreshToken),
        ),
      ],
    );
  }

  Widget _calendarFields() {
    return Column(
      children: [
        TextFormField(
          key: const Key('googleCalendarId'),
          controller: _calendarIdCtrl,
          decoration: const InputDecoration(
            labelText: 'Calendar ID',
            hintText: 'primary',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('googleBookingUrl'),
          controller: _bookingUrlCtrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Booking page URL',
            hintText: 'https://calendar.app.google/...',
            helperText:
                'Your appointment schedule link: outreach messages '
                'use it for {meetingUrl}; booked Meet calls are '
                'logged as video calls',
            helperMaxLines: 2,
            prefixIcon: Icon(Icons.event_available_outlined),
          ),
          validator: (v) {
            final t = (v ?? '').trim();
            return t.isEmpty || t.startsWith('https://')
                ? null
                : 'Must start with https://';
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showCalendarFields = _connected('calendar') || _ownClient;
    return Dialog(
      key: const Key('GoogleWorkspaceSettingsDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Connect Google Workspace',
        width: 520,
        height: 620,
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
                              _signInAvailable
                                  ? 'Sign in to let GrowERP use your Google '
                                        'files, email and calendar.'
                                  : 'Google sign in is not available on this '
                                        'server: use your own OAuth client below.',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _serviceCard(
                              service: 'all',
                              icon: Icons.apps,
                              iconColor: Colors.blue,
                              title: 'Google Drive suite',
                              description: 'Drive, Gmail and Calendar at once',
                              signInServices: const [
                                'drive',
                                'gmail',
                                'calendar',
                              ],
                              signInLabel: 'Connect all',
                            ),
                            _serviceCard(
                              service: 'drive',
                              icon: Icons.add_to_drive,
                              iconColor: Colors.green,
                              title: 'Google Drive',
                              description:
                                  'Attach Gemini meeting notes to '
                                  'lead activities',
                            ),
                            _serviceCard(
                              service: 'gmail',
                              icon: Icons.mail,
                              iconColor: Colors.red,
                              title: 'Gmail',
                              description:
                                  'Send and receive company email '
                                  'through your Gmail account',
                            ),
                            _serviceCard(
                              service: 'calendar',
                              icon: Icons.calendar_month,
                              iconColor: Colors.blue,
                              title: 'Google Calendar',
                              description:
                                  'Import Meet bookings as lead '
                                  'activities',
                            ),
                            if (_waitingFor != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Waiting for Google sign '
                                        'in to finish in the browser…',
                                      ),
                                    ),
                                    TextButton(
                                      key: const Key('googleCancelWaiting'),
                                      onPressed: _stopWaiting,
                                      child: Text(
                                        CoreLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (showCalendarFields) ...[
                              const SizedBox(height: 8),
                              _calendarFields(),
                            ],
                            const SizedBox(height: 8),
                            ExpansionTile(
                              key: const Key('googleOwnClient'),
                              tilePadding: EdgeInsets.zero,
                              initiallyExpanded:
                                  !_signInAvailable || _ownClient,
                              title: const Text('Use your own OAuth client'),
                              subtitle: Text(
                                'Scopes: calendar.readonly, drive.readonly; '
                                'add https://mail.google.com/ for Gmail',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.outline,
                                ),
                              ),
                              children: [_ownClientFields()],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sign in usually opens in a separate window.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.outline,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('googleNotNow'),
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(_changed),
                          child: const Text('Not now'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('saveGoogleWorkspaceSettings'),
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(CoreLocalizations.of(context)!.save),
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
