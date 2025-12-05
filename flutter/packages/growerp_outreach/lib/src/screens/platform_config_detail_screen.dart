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
        title: '${widget.platform.displayName} Configuration',
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
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Platform Information',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('Platform'),
                          initialValue: widget.platform.displayName,
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
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Authentication Credentials',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('API Key'),
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Platform API key',
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
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Platform username',
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
            const SizedBox(height: 24),
            _buildButtons(),
          ],
        ),
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
                        'Are you sure you want to delete the ${widget.platform.displayName} configuration?',
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
