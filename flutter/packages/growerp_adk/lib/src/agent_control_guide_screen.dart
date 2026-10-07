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

import '../l10n/generated/adk_localizations.dart';
import 'adk_config_service.dart';
import 'adk_governance_service.dart';

/// The full agent control guide, for everything this screen only touches.
final Uri agentControlGuideUrl = Uri.parse(
  'https://github.com/growerp/growerp/blob/master/docs/GrowERP_Agent_Control_Guide.md',
);

/// One step in the agent control guide.
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

/// Step-by-step guide to controlling AI agents — AI settings, agents,
/// permissions, schedules and the task loop, approvals, the audit log — with
/// live completion state, navigation to the screen of each step and a link to
/// the full agent control guide.
class AgentControlGuideScreen extends StatefulWidget {
  const AgentControlGuideScreen({super.key, this.staticMenuConfig});

  /// Menu configuration for apps without a [MenuConfigBloc] (example app).
  final MenuConfiguration? staticMenuConfig;

  @override
  State<AgentControlGuideScreen> createState() =>
      _AgentControlGuideScreenState();
}

/// Widget name of this screen in the app menu, used to switch it off.
const String _guideWidgetName = 'AgentControlGuideScreen';

class _AgentControlGuideScreenState extends State<AgentControlGuideScreen> {
  bool _llmConfigured = false;
  List<AdkAgentConfig> _agents = [];
  int _pendingApprovals = 0;

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
    _loadCompleted();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final settings = await context.read<RestClient>().getSystemSettings();
      if (mounted) {
        setState(() => _llmConfigured = settings.llmConfigs.isNotEmpty);
      }
    } catch (_) {
      // leave the step unchecked when the settings cannot be read
    }
    try {
      final agents = await (await AdkConfigService.create()).list();
      if (mounted) setState(() => _agents = agents);
    } catch (_) {
      // no agents readable: the agent steps stay unchecked
    }
    try {
      final pending = await (await AdkGovernanceService.create()).approvals();
      if (mounted) setState(() => _pendingApprovals = pending.length);
    } catch (_) {
      // approvals unreadable: shown as none pending
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
  void _hideGuide(AdkLocalizations localizations) {
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
      SnackBar(content: Text(localizations.adk_guideHiddenMessage)),
    );
  }

  Future<void> _confirmHideGuide(AdkLocalizations localizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('hideGuideDialog'),
        title: Text(localizations.adk_guideHideConfirmTitle),
        content: Text(localizations.adk_guideHideConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            key: const Key('hideGuideConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localizations.adk_guideHide),
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
    bool inMenu(MenuItem item) =>
        item.widgetName == widgetName ||
        (item.children ?? []).any(
          (child) => child.isActive && child.widgetName == widgetName,
        );
    // System Setup sits in a submenu several apps reach from their settings
    return widgetName == 'SystemSetupDialog' ||
        (_menuConfig?.menuItems ?? []).any(inMenu);
  }

  /// Storage key of the completed steps, per company and user.
  String get _completedKey {
    final authenticate = context.read<AuthBloc>().state.authenticate;
    return 'agentControlGuide_${authenticate?.company?.partyId ?? ''}'
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

  List<_GuideStep> _steps(AdkLocalizations localizations) {
    final agents = _agents;
    final readOnly = agents.where((a) => (a.toolMode ?? 'readOnly') == 'readOnly');
    // an agent that may write and does so without asking anyone
    final unchecked = agents.where(
      (a) => (a.toolMode ?? 'readOnly') != 'readOnly' && a.writePolicy == 'allow',
    );
    final scheduled = agents.where((a) => a.scheduleEnabled);
    final loops = agents.where((a) => a.scheduleEnabled && a.loopEnabled);

    return [
      _GuideStep(
        id: 'aiSettings',
        icon: Icons.psychology,
        title: localizations.adk_guideStep1Title,
        description: localizations.adk_guideStep1Desc,
        targetWidgetName: 'SystemSetupDialog',
        checked: _llmConfigured,
        status: _llmConfigured
            ? localizations.adk_guideStatusLlm
            : localizations.adk_guideStatusNoLlm,
      ),
      _GuideStep(
        id: 'agents',
        icon: Icons.smart_toy,
        title: localizations.adk_guideStep2Title,
        description: localizations.adk_guideStep2Desc,
        targetWidgetName: 'AdkAgentListView',
        checked: agents.isNotEmpty,
        status: agents.isEmpty
            ? localizations.adk_guideStatusNoAgents
            : localizations.adk_guideStatusAgents(agents.length),
      ),
      _GuideStep(
        id: 'permissions',
        icon: Icons.shield_outlined,
        title: localizations.adk_guideStep3Title,
        description: localizations.adk_guideStep3Desc,
        targetWidgetName: 'AdkAgentListView',
        checked: agents.isNotEmpty && unchecked.isEmpty,
        status: agents.isEmpty
            ? localizations.adk_guideStatusNoAgents
            : unchecked.isNotEmpty
                ? localizations.adk_guideStatusWritesAllowed(unchecked.length)
                : localizations.adk_guideStatusPermissions(
                    readOnly.length,
                    agents.length - readOnly.length,
                  ),
      ),
      _GuideStep(
        id: 'schedule',
        icon: Icons.schedule,
        title: localizations.adk_guideStep4Title,
        description: localizations.adk_guideStep4Desc,
        targetWidgetName: 'AdkAgentListView',
        optional: true,
        checked: scheduled.isNotEmpty,
        status: scheduled.isEmpty
            ? localizations.adk_guideStatusNoSchedule
            : localizations.adk_guideStatusScheduled(
                scheduled.length,
                loops.length,
              ),
      ),
      _GuideStep(
        id: 'approvals',
        icon: Icons.fact_check,
        title: localizations.adk_guideStep5Title,
        description: localizations.adk_guideStep5Desc,
        targetWidgetName: 'AdkApprovalsListView',
        checked: _completed.contains('approvals') && _pendingApprovals == 0,
        status: _pendingApprovals > 0
            ? localizations.adk_guideStatusPending(_pendingApprovals)
            : localizations.adk_guideStatusNoPending,
      ),
      _GuideStep(
        id: 'actions',
        icon: Icons.history,
        title: localizations.adk_guideStep6Title,
        description: localizations.adk_guideStep6Desc,
        targetWidgetName: 'AdkActionsListView',
        status: _statusOfOpened('actions', localizations),
      ),
      _GuideStep(
        id: 'jobs',
        icon: Icons.work_history_outlined,
        title: localizations.adk_guideStep7Title,
        description: localizations.adk_guideStep7Desc,
        targetWidgetName: 'AdkJobListView',
        optional: true,
        status: _statusOfOpened('jobs', localizations),
      ),
    ];
  }

  /// Status of a step that is completed by opening it.
  String _statusOfOpened(String id, AdkLocalizations localizations) =>
      _completed.contains(id)
          ? localizations.adk_guideStatusOpened
          : localizations.adk_guideStatusNotOpened;

  @override
  Widget build(BuildContext context) {
    final localizations = AdkLocalizations.of(context)!;
    final steps = _steps(localizations);

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
      key: const Key('AgentControlGuide'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            key: const Key('listView'),
            padding: const EdgeInsets.all(16),
            itemCount: steps.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _header(localizations);
              if (index == steps.length + 1) return _fullGuide(localizations);
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

  Widget _header(AdkLocalizations localizations) {
    final guideItem = _guideMenuItem;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.adk_guideTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (widget.staticMenuConfig == null &&
                  guideItem?.menuItemId != null)
                IconButton(
                  key: const Key('hideGuide'),
                  icon: const Icon(Icons.visibility_off),
                  tooltip: localizations.adk_guideHide,
                  onPressed: () => _confirmHideGuide(localizations),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizations.adk_guideIntro,
            key: const Key('guideIntro'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Link to the full guide, below the steps.
  Widget _fullGuide(AdkLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          key: const Key('fullGuide'),
          leading: const Icon(Icons.menu_book),
          title: Text(localizations.adk_guideFullTitle),
          subtitle: Text(localizations.adk_guideFullDesc),
          trailing: const Icon(Icons.open_in_new),
          onTap: () async {
            if (!await openExternalUrl(agentControlGuideUrl) && mounted) {
              HelperFunctions.showMessage(
                context,
                agentControlGuideUrl.toString(),
                Colors.orange,
              );
            }
          },
        ),
      ),
    );
  }

  /// The screen of [step] with a bar on top returning to the guide.
  Widget _stepScreen(AdkLocalizations localizations, _GuideStep step) {
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
                  Text(localizations.adk_guideBackToGuide),
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
    AdkLocalizations localizations,
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
                  localizations.adk_guideNotAvailable,
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
                                '(${localizations.adk_guideOptional})',
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
