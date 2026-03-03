/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/platform_config_bloc.dart';

class PlatformConfigDetailScreen extends StatefulWidget {
  final OutreachPlatform platform;
  final PlatformConfiguration? config;

  const PlatformConfigDetailScreen({
    super.key,
    required this.platform,
    this.config,
  });

  @override
  State<PlatformConfigDetailScreen> createState() =>
      _PlatformConfigDetailScreenState();
}

class _PlatformConfigDetailScreenState
    extends State<PlatformConfigDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dailyLimitController;
  late TextEditingController _apiKeyController;
  late TextEditingController _apiSecretController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late bool _isEnabled;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _dailyLimitController = TextEditingController(
      text: widget.config?.dailyLimit.toString() ?? '50',
    );
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
    _apiSecretController = TextEditingController(
      text: widget.config?.apiSecret ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.config?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.config?.password ?? '',
    );
    _isEnabled = widget.config?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;

    return Dialog(
      key: Key('PlatformConfigDetail_${widget.platform.name}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: '${widget.platform.name} Configuration',
        width: isPhone ? 400 : 600,
        height: isPhone ? 700 : 700,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BlocListener<PlatformConfigBloc, PlatformConfigState>(
              listener: (context, state) {
                if (state.status == PlatformConfigStatus.success &&
                    (state.message ?? '').isNotEmpty &&
                    !_isClosing) {
                  // Only pop the dialog once, not the entire route
                  _isClosing = true;
                  Navigator.of(context).pop();
                }
                if (state.status == PlatformConfigStatus.failure) {
                  HelperFunctions.showMessage(
                    context,
                    state.message ?? 'An error occurred',
                    Colors.red,
                  );
                }
              },
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupingDecorator(
              labelText: 'Platform Information',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('Platform'),
                          initialValue: widget.platform.name,
                          decoration:
                              const InputDecoration(labelText: 'Platform'),
                          readOnly: true,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    key: const Key('Enabled'),
                    title: const Text('Enabled'),
                    subtitle: const Text('Allow outreach on this platform'),
                    value: _isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('Daily Limit'),
                          controller: _dailyLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Daily Limit',
                            hintText: 'Max messages per day',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a daily limit';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GroupingDecorator(
              labelText: 'Authentication Credentials',
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('API Key'),
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: _apiKeyLabel,
                      hintText: _apiKeyHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('API Secret'),
                    controller: _apiSecretController,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      hintText: 'Platform API secret',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('Username'),
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: _usernameLabel,
                      hintText: _usernameHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('Password'),
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Platform password',
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            if (_helpSteps != null) ...[
              const SizedBox(height: 16),
              _buildHelpCard(),
            ],
            const SizedBox(height: 24),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  // ── Platform-specific field labels ──────────────────────────────────────

  String get _apiKeyLabel => switch (widget.platform) {
        OutreachPlatform.substack => 'Session Cookie (substack.sid)',
        OutreachPlatform.linkedIn => 'OAuth 2.0 Access Token',
        _ => 'API Key',
      };

  String get _apiKeyHint => switch (widget.platform) {
        OutreachPlatform.substack => 'Paste value of substack.sid cookie',
        OutreachPlatform.linkedIn =>
          'Bearer token from LinkedIn developer portal',
        _ => 'Platform API key',
      };

  String get _usernameLabel => switch (widget.platform) {
        OutreachPlatform.substack => 'Publication URL',
        OutreachPlatform.linkedIn => 'Person URN',
        _ => 'Username',
      };

  String get _usernameHint => switch (widget.platform) {
        OutreachPlatform.substack => 'https://yourname.substack.com',
        OutreachPlatform.linkedIn => 'urn:li:person:AbCdEfGhIj',
        _ => 'Platform username',
      };

  // ── Help steps (null = no help card shown) ──────────────────────────────

  List<_HelpStep>? get _helpSteps => switch (widget.platform) {
        OutreachPlatform.substack => const [
            _HelpStep(
              icon: Icons.login,
              title: 'Log in to Substack',
              body:
                  'Open substack.com in your browser and sign in to your account.',
            ),
            _HelpStep(
              icon: Icons.developer_mode,
              title: 'Open DevTools → Cookies',
              body:
                  'Press F12 (or right-click → Inspect). Go to Application → Storage → Cookies → https://substack.com.',
            ),
            _HelpStep(
              icon: Icons.key,
              title: 'Copy substack.sid',
              body:
                  'Find the row named substack.sid. Click its Value cell, select all, and copy. Paste it into the Session Cookie field above.',
            ),
            _HelpStep(
              icon: Icons.link,
              title: 'Enter your publication URL',
              body:
                  'This is the base URL of your newsletter, e.g. https://yourname.substack.com. Find it on your Substack dashboard.',
            ),
            _HelpStep(
              icon: Icons.warning_amber,
              title: 'Cookie expires on logout',
              body:
                  'The substack.sid cookie is invalidated when you log out. If publishing fails with an auth error, repeat these steps to get a fresh cookie.',
            ),
          ],
        OutreachPlatform.linkedIn => const [
            _HelpStep(
              icon: Icons.app_registration,
              title: 'Create a LinkedIn developer app',
              body:
                  'Go to linkedin.com/developers → My Apps → Create app. Request the "Share on LinkedIn" product to unlock the w_member_social scope.',
            ),
            _HelpStep(
              icon: Icons.vpn_key,
              title: 'Generate an access token',
              body:
                  'Inside your app go to Auth → OAuth 2.0 tools → Generate access token. Select the w_member_social scope and authorise with your LinkedIn account.',
            ),
            _HelpStep(
              icon: Icons.key,
              title: 'Paste the token',
              body:
                  'Copy the generated access token and paste it into the OAuth 2.0 Access Token field above. Tokens typically expire after 60 days.',
            ),
            _HelpStep(
              icon: Icons.person,
              title: 'Find your Person URN',
              body:
                  'Call https://api.linkedin.com/v2/me with your token (use the OAuth tools page or curl -H "Authorization: Bearer {token}" https://api.linkedin.com/v2/me). The "id" value gives the last segment — your URN is urn:li:person:{id}.',
            ),
          ],
        _ => null,
      };

  Widget _buildHelpCard() {
    final steps = _helpSteps!;
    final color = widget.platform == OutreachPlatform.substack
        ? const Color(0xFFFF6719)
        : const Color(0xFF0A66C2);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: ExpansionTile(
        key: const Key('credentialHelp'),
        leading: Icon(Icons.help_outline, color: color),
        title: Text(
          'How to get ${widget.platform.name} credentials',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(steps[i].icon, size: 16, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(steps[i].body,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1) const Divider(height: 20),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        if (widget.config != null) ...[
          Expanded(
            child: OutlinedButton(
              key: const Key('Delete'),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Configuration'),
                      content: Text(
                        'Are you sure you want to delete the ${widget.platform.name} configuration?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true && mounted) {
                  context.read<PlatformConfigBloc>().add(
                        PlatformConfigDelete(widget.config!.configId!),
                      );
                }
              },
              child: const Text('Delete'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: OutlinedButton(
            key: Key(widget.config == null ? 'Create' : 'Update'),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final config = PlatformConfiguration(
                  configId: widget.config?.configId,
                  platform: widget.platform.name,
                  isEnabled: _isEnabled,
                  dailyLimit: int.parse(_dailyLimitController.text),
                  apiKey: _apiKeyController.text.isEmpty
                      ? null
                      : _apiKeyController.text,
                  apiSecret: _apiSecretController.text.isEmpty
                      ? null
                      : _apiSecretController.text,
                  username: _usernameController.text.isEmpty
                      ? null
                      : _usernameController.text,
                  password: _passwordController.text.isEmpty
                      ? null
                      : _passwordController.text,
                );

                if (widget.config == null) {
                  context
                      .read<PlatformConfigBloc>()
                      .add(PlatformConfigCreate(config));
                } else {
                  context
                      .read<PlatformConfigBloc>()
                      .add(PlatformConfigUpdate(config));
                }
              }
            },
            child: Text(widget.config == null ? 'Create' : 'Update'),
          ),
        ),
      ],
    );
  }
}

class _HelpStep {
  final IconData icon;
  final String title;
  final String body;

  const _HelpStep({
    required this.icon,
    required this.title,
    required this.body,
  });
}
