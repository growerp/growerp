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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'package:growerp_outreach/l10n/generated/outreach_localizations.dart';

import '../bloc/outreach_campaign_bloc.dart';
import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import '../bloc/outreach_message_state.dart';
import '../bloc/platform_config_bloc.dart';

/// One step in the outreach setup guide.
class _GuideStep {
  const _GuideStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    this.targetWidgetName,
    this.optional = false,
    this.checked,
  });

  /// Stable id, used to remember steps the user completed by hand.
  final String id;
  final IconData icon;
  final String title;
  final String description;

  /// What is missing, or what the current state of this step is.
  final String status;

  /// Widget name of the destination screen, looked up in the app menu.
  final String? targetWidgetName;
  final bool optional;

  /// Live completion check, null when the step cannot be checked from data
  /// and is completed by opening it instead.
  final bool? checked;
}

/// Step-by-step guide showing how to run outreach, with live completion
/// state and navigation to the screen belonging to each step.
class OutreachSetupGuideScreen extends StatefulWidget {
  const OutreachSetupGuideScreen({super.key, this.staticMenuConfig});

  /// Menu configuration for apps without a [MenuConfigBloc] (example app).
  final MenuConfiguration? staticMenuConfig;

  @override
  State<OutreachSetupGuideScreen> createState() =>
      _OutreachSetupGuideScreenState();
}

/// Widget name of this screen in the app menu, used to switch it off.
const String _guideWidgetName = 'OutreachSetupGuideScreen';

class _OutreachSetupGuideScreenState extends State<OutreachSetupGuideScreen> {
  bool _smtpConfigured = false;
  bool _llmConfigured = false;

  /// Ids of the steps without a live check that the user opened, kept on this
  /// device so the guide shows the same progress on the next visit.
  Set<String> _completed = {};

  /// Step whose screen is currently shown instead of the step list.
  _GuideStep? _openStep;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  /// (Re)loads everything the completion checks are based on.
  void _loadState() {
    context.read<PlatformConfigBloc>().add(const PlatformConfigFetch());
    context.read<OutreachCampaignBloc>().add(const OutreachCampaignFetch());
    context.read<OutreachMessageBloc>().add(const OutreachMessageLoad());
    _loadCompleted();
    _fetchSystemSettings();
  }

  Future<void> _fetchSystemSettings() async {
    try {
      final settings = await context.read<RestClient>().getSystemSettings();
      if (!mounted) return;
      setState(() {
        _smtpConfigured = (settings.smtpHost ?? '').isNotEmpty;
        _llmConfigured = settings.llmConfigs.isNotEmpty;
      });
    } catch (_) {
      // leave the step unchecked when the settings cannot be read
    }
  }

  /// Menu configuration of the running app, used to check step availability.
  MenuConfiguration? get _menuConfig {
    if (widget.staticMenuConfig != null) return widget.staticMenuConfig;
    try {
      return context.read<MenuConfigBloc>().state.menuConfiguration;
    } catch (_) {
      return null;
    }
  }

  /// Menu item of the guide itself, used to switch the guide off. Null when
  /// the app has no menu configuration (example app) or no guide menu item.
  MenuItem? get _guideMenuItem {
    for (final item in _menuConfig?.menuItems ?? <MenuItem>[]) {
      if (item.widgetName == _guideWidgetName) return item;
      for (final child in item.children ?? <MenuItem>[]) {
        if (child.widgetName == _guideWidgetName) return child;
      }
    }
    return null;
  }

  /// Switches the guide off for this user, in every app.
  void _hideGuide(OutreachLocalizations localizations) {
    // The menu reload disposes this screen, so take what is needed from the
    // context before the event is added.
    final messenger = ScaffoldMessenger.of(context);
    context.read<MenuConfigBloc>().add(
      const MenuWidgetVisibilitySet(
        widgetName: _guideWidgetName,
        hidden: true,
      ),
    );
    messenger.showSnackBar(
      SnackBar(content: Text(localizations.guideHiddenMessage)),
    );
  }

  Future<void> _confirmHideGuide(OutreachLocalizations localizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('hideGuideDialog'),
        title: Text(localizations.guideHideConfirmTitle),
        content: Text(localizations.guideHideConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            key: const Key('hideGuideConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localizations.guideHide),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _hideGuide(localizations);
  }

  /// True when [widgetName] is both part of this app's menu and registered,
  /// so its screen can be shown from the guide.
  bool _isAvailable(String? widgetName) {
    if (widgetName == null || !WidgetRegistry.hasWidget(widgetName)) {
      return false;
    }
    return (_menuConfig?.menuItems ?? []).any(
      (item) =>
          item.widgetName == widgetName ||
          (item.children ?? []).any(
            (child) => child.isActive && child.widgetName == widgetName,
          ),
    );
  }

  /// Storage key of the completed steps, per company and user.
  String get _completedKey {
    final authenticate = context.read<AuthBloc>().state.authenticate;
    return 'outreachGuide_${authenticate?.company?.partyId ?? ''}'
        '_${authenticate?.user?.userId ?? ''}';
  }

  Future<void> _loadCompleted() async {
    final stored = await PersistFunctions.getKeyValue(_completedKey);
    if (!mounted || stored == null) return;
    setState(
      () => _completed = (jsonDecode(stored) as List).cast<String>().toSet(),
    );
  }

  /// Shows the screen of [step] in place of the step list, keeping the app
  /// frame (navigation rail / drawer, app bar) of the guide. Steps without a
  /// live check count as completed once they have been opened.
  void _showStep(_GuideStep step) {
    setState(() {
      _openStep = step;
      if (step.checked == null) _completed.add(step.id);
    });
    if (step.checked == null) {
      PersistFunctions.persistKeyValue(
        _completedKey,
        jsonEncode(_completed.toList()),
      );
    }
  }

  /// Returns to the step list and refreshes the completion state.
  void _backToGuide() {
    setState(() => _openStep = null);
    _loadState();
  }

  List<_GuideStep> _steps(
    OutreachLocalizations localizations,
    PlatformConfigState platformState,
    OutreachCampaignState campaignState,
    OutreachMessageState messageState,
  ) {
    final enabledPlatforms = platformState.configs.where((c) => c.isEnabled);
    final campaigns = campaignState.campaigns;
    final running = campaigns.where(
      (c) =>
          c.status == 'MKTG_CAMP_INPROGRESS' || c.status == 'MKTG_CAMP_APPROVED',
    );
    final messages = messageState.messages;
    final sent = messages.where((m) => m.status == 'SENT');
    final responded = messages.where((m) => m.status == 'RESPONDED');

    return [
      _GuideStep(
        id: 'systemSetup',
        icon: Icons.settings,
        title: localizations.guideStep1Title,
        description: localizations.guideStep1Desc,
        targetWidgetName: 'SystemSetupDialog',
        checked: _smtpConfigured && _llmConfigured,
        status: _smtpConfigured && _llmConfigured
            ? localizations.guideStatusSystemOk
            : _llmConfigured
                ? localizations.guideStatusSystemNoSmtp
                : _smtpConfigured
                    ? localizations.guideStatusSystemNoLlm
                    : localizations.guideStatusSystemNothing,
      ),
      _GuideStep(
        id: 'platforms',
        icon: Icons.public,
        title: localizations.guideStep2Title,
        description: localizations.guideStep2Desc,
        targetWidgetName: 'PlatformConfigListScreen',
        checked: enabledPlatforms.isNotEmpty,
        status: enabledPlatforms.isEmpty
            ? localizations.guideStatusNoPlatforms
            : localizations.guideStatusPlatforms(enabledPlatforms.length),
      ),
      _GuideStep(
        id: 'audience',
        icon: Icons.people,
        title: localizations.guideStep3Title,
        description: localizations.guideStep3Desc,
        targetWidgetName: 'PersonaList',
        optional: true,
        status: _statusOfOpened('audience', localizations),
      ),
      _GuideStep(
        id: 'campaign',
        icon: Icons.campaign,
        title: localizations.guideStep4Title,
        description: localizations.guideStep4Desc,
        targetWidgetName: 'CampaignListScreen',
        checked: campaigns.isNotEmpty,
        status: campaigns.isEmpty
            ? localizations.guideStatusNoCampaigns
            : localizations.guideStatusCampaigns(campaigns.length),
      ),
      _GuideStep(
        id: 'recipients',
        icon: Icons.group_add,
        title: localizations.guideStep5Title,
        description: localizations.guideStep5Desc,
        targetWidgetName: 'CampaignListScreen',
        checked: messages.isNotEmpty,
        status: messages.isEmpty
            ? localizations.guideStatusNoRecipients
            : localizations.guideStatusRecipients(messages.length),
      ),
      _GuideStep(
        id: 'automation',
        icon: Icons.play_circle_outline,
        title: localizations.guideStep6Title,
        description: localizations.guideStep6Desc,
        targetWidgetName: 'AutomationScreen',
        checked: running.isNotEmpty,
        status: running.isEmpty
            ? localizations.guideStatusNotRunning
            : localizations.guideStatusRunning(running.length),
      ),
      _GuideStep(
        id: 'sendQueue',
        icon: Icons.send,
        title: localizations.guideStep7Title,
        description: localizations.guideStep7Desc,
        targetWidgetName: 'LinkedInSendQueueScreen',
        status: _statusOfOpened('sendQueue', localizations),
      ),
      _GuideStep(
        id: 'responses',
        icon: Icons.message,
        title: localizations.guideStep8Title,
        description: localizations.guideStep8Desc,
        targetWidgetName: 'OutreachMessageList',
        checked: sent.isNotEmpty || responded.isNotEmpty,
        status: sent.isEmpty && responded.isEmpty
            ? localizations.guideStatusNoMessages
            : localizations.guideStatusMessages(sent.length, responded.length),
      ),
      _GuideStep(
        id: 'leads',
        icon: Icons.person_add,
        title: localizations.guideStep9Title,
        description: localizations.guideStep9Desc,
        targetWidgetName: 'UserListLead',
        status: _statusOfOpened('leads', localizations),
      ),
    ];
  }

  /// Status of a step that is completed by opening it.
  String _statusOfOpened(String id, OutreachLocalizations localizations) =>
      _completed.contains(id)
          ? localizations.guideStatusOpened
          : localizations.guideStatusNotOpened;

  @override
  Widget build(BuildContext context) {
    final localizations = OutreachLocalizations.of(context)!;
    final platformState = context.watch<PlatformConfigBloc>().state;
    final campaignState = context.watch<OutreachCampaignBloc>().state;
    final messageState = context.watch<OutreachMessageBloc>().state;
    final steps =
        _steps(localizations, platformState, campaignState, messageState);

    final openStep = _openStep;
    if (openStep != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _backToGuide();
        },
        child: _stepScreen(localizations, openStep),
      );
    }

    return Scaffold(
      key: const Key('OutreachSetupGuide'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            key: const Key('listView'),
            padding: const EdgeInsets.all(16),
            itemCount: steps.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final guideItem = _guideMenuItem;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.guideTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (widget.staticMenuConfig == null &&
                          guideItem?.menuItemId != null)
                        IconButton(
                          key: const Key('hideGuide'),
                          icon: const Icon(Icons.visibility_off),
                          tooltip: localizations.guideHide,
                          onPressed: () => _confirmHideGuide(localizations),
                        ),
                    ],
                  ),
                );
              }
              final stepIndex = index - 1;
              return _stepCard(
                localizations,
                steps[stepIndex],
                stepIndex,
                isLast: stepIndex == steps.length - 1,
              );
            },
          ),
        ),
      ),
    );
  }

  /// The screen of [step] with a bar on top returning to the guide.
  Widget _stepScreen(OutreachLocalizations localizations, _GuideStep step) {
    final theme = Theme.of(context);
    final widgetName = step.targetWidgetName!;

    return Column(
      key: const Key('guideStepPage'),
      children: [
        Material(
          color: theme.colorScheme.secondaryContainer,
          child: InkWell(
            key: const Key('backToGuide'),
            onTap: _backToGuide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: 8),
                  Text(localizations.guideBackToGuide),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '| ${step.title}',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          // Keyed with the widget name, same as the router does, so the
          // opened screen is discoverable by tests.
          child: KeyedSubtree(
            key: Key(widgetName),
            child: WidgetRegistry.getWidget(widgetName),
          ),
        ),
      ],
    );
  }

  Widget _stepCard(
    OutreachLocalizations localizations,
    _GuideStep step,
    int index, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final available = _isAvailable(step.targetWidgetName);
    final done = step.checked ?? _completed.contains(step.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            key: Key('guideStep$index'),
            onTap: () {
              if (!available) {
                HelperFunctions.showMessage(
                  context,
                  localizations.guideNotAvailable,
                  Colors.orange,
                );
                return;
              }
              _showStep(step);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: done
                        ? Colors.green
                        : theme.colorScheme.secondaryContainer,
                    child: done
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text('${index + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(step.icon, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                step.title,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            if (step.optional)
                              Text(
                                '(${localizations.guideOptional})',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.status,
                          key: Key('guideStatus$index'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: done ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (available)
                    const Icon(Icons.chevron_right)
                  else
                    const SizedBox(width: 24),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Container(
              width: 2,
              height: 16,
              color: theme.dividerColor,
            ),
          ),
      ],
    );
  }
}
