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
import 'package:genui/genui.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../common/bloc/menu_config_bloc.dart';
import '../../common/widgets/loading_indicator.dart';
import '../bloc/onboarding_bloc.dart';
import '../catalog/onboarding_catalog.dart';
import '../catalog/onboarding_prompts.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key, required this.authenticate});
  final Authenticate authenticate;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  late final A2uiTransportAdapter _adapter;
  late final SurfaceController _controller;
  late final Conversation _conversation;
  late final String _systemPrompt;
  late final String _classificationId;

  final List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  Future<void> _onUserMessage(String text) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _history.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ],
    });
    try {
      final result = await context.read<RestClient>().chatOnboarding({
        'classificationId': _classificationId,
        'systemPrompt': _systemPrompt,
        'messages': _history,
      });
      final jsonl = result['jsonl']?.toString() ?? '';
      if (jsonl.isEmpty) {
        if (mounted) {
          try {
            await context.read<RestClient>().saveOnboarding({
              'classificationId': _classificationId,
              'menuConfig': <String, dynamic>{},
              'conversation': <Map<String, dynamic>>[],
            });
          } catch (e) {
            debugPrint('saveOnboarding (no-AI path) failed: $e');
          }
          if (mounted) Navigator.of(context).pop();
        }
        return;
      }
      _history.add({
        'role': 'model',
        'parts': [
          {'text': jsonl}
        ],
      });
      _adapter.addChunk(jsonl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCompletion(OnboardingMenuConfig menuConfig) async {
    // Save the conversation as a ChatRoom for support review
    try {
      final result = await context.read<RestClient>().saveOnboarding({
        'classificationId': menuConfig.classificationId,
        'menuConfig': menuConfig.toJson(),
        'conversation': _history,
      });
      if (result['errors'] != null) {
        debugPrint('saveOnboarding errors: ${result['errors']}');
      }
    } catch (e) {
      debugPrint('saveOnboarding failed: $e');
    }

    if (!mounted) return;
    final restClient = context.read<RestClient>();
    // classificationId is "AppAdmin"/"AppHotel"/etc. but menu seed data uses
    // "admin"/"hotel"/etc. — read the correct appId from MenuConfigBloc.
    final appId = context.read<MenuConfigBloc>().appId;

    try {
      // 1. Load default menu AND any existing user-specific menu
      final defaultMenu = await restClient.getMenuConfiguration(
        appId: appId,
      );
      // Reset any stale user config from previous (failed) onboarding runs
      // so the clone starts from a clean default
      try {
        final userMenu = await restClient.getMenuConfiguration(
          appId: appId,
          userVersion: true,
        );
        if (userMenu.menuConfigurationId != null &&
            userMenu.menuConfigurationId != defaultMenu.menuConfigurationId) {
          await restClient.resetMenuConfiguration(
            menuConfigurationId: userMenu.menuConfigurationId!,
          );
        }
      } catch (_) {} // no user version exists yet — fine

      // 2. Clone the default as a user-specific menu (returns shell, no items)
      final clonedShell = await restClient.cloneMenuConfiguration(
        sourceMenuConfigurationId: defaultMenu.menuConfigurationId!,
        name: menuConfig.name,
      );
      // Fetch the full cloned menu with all item IDs.
      // userVersion: true is required — without it the service filters userId=null
      // (seed data path) and never finds the freshly cloned user config.
      final cloned = await restClient.getMenuConfiguration(
        menuConfigurationId: clonedShell.menuConfigurationId,
        userVersion: true,
      );

      // Match by ROUTE — more stable than widgetName (AI may use slightly
      // different widget names but routes are fixed in the system prompt).
      // Always keep '/' (dashboard root) visible.
      final selectedRoutes = {
        '/',
        ...menuConfig.menuItems.map((i) => i.route.toLowerCase()),
      };

      // 3. Minimize every item whose route is NOT in the AI's selection
      for (final item in cloned.menuItems) {
        final route = item.route?.toLowerCase() ?? '';
        if (!selectedRoutes.contains(route) && item.menuItemId != null) {
          try {
            await restClient.updateMenuItem(
              menuItemId: item.menuItemId!,
              isMinimized: 'Y',
            );
          } catch (e) {
            debugPrint('minimize ${item.route} failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('menu setup failed: $e');
    }

    if (!mounted) return;
    // 4. Reload the user-specific menu so the dashboard reflects the config
    context.read<MenuConfigBloc>().add(MenuConfigLoad(userVersion: true));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _classificationId = context.read<OnboardingBloc>().classificationId;

    final catalog = buildOnboardingCatalog(
      onUserMessage: _onUserMessage,
      onFinalize: _handleCompletion,
      classificationId: _classificationId,
    );

    _adapter = A2uiTransportAdapter();
    _controller = SurfaceController(catalogs: [catalog]);
    _conversation = Conversation(controller: _controller, transport: _adapter);
    _systemPrompt = OnboardingPrompts.forApp(_classificationId, catalog);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onUserMessage('Start onboarding.');
    });
  }

  @override
  void dispose() {
    _conversation.dispose();
    _controller.dispose();
    _adapter.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: SizedBox()),
            TextButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await context.read<RestClient>().saveOnboarding({
                    'classificationId': _classificationId,
                    'menuConfig': <String, dynamic>{},
                    'conversation': <Map<String, dynamic>>[],
                  });
                } catch (e) {
                  debugPrint('saveOnboarding (Skip path) failed: $e');
                }
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Skip'),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            "Let's set up your workspace — takes about 2 minutes.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: ValueListenableBuilder<ConversationState>(
                valueListenable: _conversation.state,
                builder: (context, state, _) {
                  if (state.surfaces.isEmpty) {
                    return const Center(child: LoadingIndicator());
                  }
                  return Surface(
                    surfaceContext:
                        _controller.contextFor(state.surfaces.last),
                    defaultBuilder: (_) =>
                        const Center(child: LoadingIndicator()),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
