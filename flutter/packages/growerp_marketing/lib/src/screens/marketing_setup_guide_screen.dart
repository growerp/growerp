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

import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

import '../bloc/content_plan_bloc.dart';
import '../bloc/content_plan_event.dart';
import '../bloc/content_plan_state.dart';
import '../bloc/master_content_bloc.dart';
import '../bloc/master_content_event.dart';
import '../bloc/master_content_state.dart';
import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';
import '../bloc/persona_state.dart';
import '../bloc/social_post_bloc.dart';
import '../bloc/social_post_event.dart';
import '../bloc/social_post_state.dart';

/// One step in the marketing setup guide.
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

/// Step-by-step guide through the content machine — persona, plan, write,
/// approve, adapt, publish — with live completion state and navigation to the
/// screen belonging to each step.
class MarketingSetupGuideScreen extends StatefulWidget {
  const MarketingSetupGuideScreen({super.key, this.staticMenuConfig});

  /// Menu configuration for apps without a [MenuConfigBloc] (example app).
  final MenuConfiguration? staticMenuConfig;

  @override
  State<MarketingSetupGuideScreen> createState() =>
      _MarketingSetupGuideScreenState();
}

/// Widget name of this screen in the app menu, used to switch it off.
const String _guideWidgetName = 'MarketingSetupGuideScreen';

class _MarketingSetupGuideScreenState extends State<MarketingSetupGuideScreen> {
  bool _llmConfigured = false;
  bool _ownVoice = false;

  /// Platforms are configured in the outreach package. They are read straight
  /// from the REST client rather than from its bloc, so this package keeps
  /// depending only on core and models.
  int _enabledPlatforms = 0;

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
    context.read<PersonaBloc>().add(const PersonaFetch(refresh: true));
    context.read<ContentPlanBloc>().add(const ContentPlanFetch(refresh: true));
    context.read<MasterContentBloc>().add(
      const MasterContentFetch(refresh: true),
    );
    context.read<SocialPostBloc>().add(const SocialPostFetch(refresh: true));
    _loadCompleted();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final restClient = context.read<RestClient>();
    try {
      final settings = await restClient.getSystemSettings();
      if (!mounted) return;
      setState(() {
        _llmConfigured = settings.llmConfigs.isNotEmpty;
        _ownVoice = (settings.writingStyle ?? '').isNotEmpty;
      });
    } catch (_) {
      // leave the step unchecked when the settings cannot be read
    }
    try {
      final configs = await restClient.listPlatformConfigurations();
      if (!mounted) return;
      setState(() {
        _enabledPlatforms = configs.configs.where((c) => c.isEnabled).length;
      });
    } catch (_) {
      // an app without the outreach package cannot read them
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
  void _hideGuide(MarketingLocalizations localizations) {
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
      SnackBar(content: Text(localizations.mktGuideHiddenMessage)),
    );
  }

  Future<void> _confirmHideGuide(MarketingLocalizations localizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('hideGuideDialog'),
        title: Text(localizations.mktGuideHideConfirmTitle),
        content: Text(localizations.mktGuideHideConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            key: const Key('hideGuideConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localizations.mktGuideHide),
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
    return 'marketingGuide_${authenticate?.company?.partyId ?? ''}'
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
    MarketingLocalizations localizations,
    PersonaState personaState,
    ContentPlanState planState,
    MasterContentState contentState,
    SocialPostState postState,
  ) {
    final personas = personaState.personas;
    final plans = planState.contentPlans;
    final contents = contentState.masterContents;
    final approved = contents.where((c) => c.approvedDate != null);
    final posts = postState.socialPosts;
    final published = posts.where((p) => p.status == 'PUBLISHED');

    return [
      _GuideStep(
        id: 'systemSetup',
        icon: Icons.psychology,
        title: localizations.mktGuideStep1Title,
        description: localizations.mktGuideStep1Desc,
        targetWidgetName: 'SystemSetupDialog',
        checked: _llmConfigured,
        status: !_llmConfigured
            ? localizations.mktGuideStatusNoLlm
            : _ownVoice
                ? localizations.mktGuideStatusOwnVoice
                : localizations.mktGuideStatusDefaultVoice,
      ),
      _GuideStep(
        id: 'persona',
        icon: Icons.person_outline,
        title: localizations.mktGuideStep2Title,
        description: localizations.mktGuideStep2Desc,
        targetWidgetName: 'PersonaList',
        checked: personas.isNotEmpty,
        status: personas.isEmpty
            ? localizations.mktGuideStatusNoPersonas
            : localizations.mktGuideStatusPersonas(personas.length),
      ),
      _GuideStep(
        id: 'platforms',
        icon: Icons.public,
        title: localizations.mktGuideStep3Title,
        description: localizations.mktGuideStep3Desc,
        targetWidgetName: 'PlatformConfigListScreen',
        checked: _enabledPlatforms > 0,
        status: _enabledPlatforms == 0
            ? localizations.mktGuideStatusNoPlatforms
            : localizations.mktGuideStatusPlatforms(_enabledPlatforms),
      ),
      _GuideStep(
        id: 'contentPlan',
        icon: Icons.calendar_month,
        title: localizations.mktGuideStep4Title,
        description: localizations.mktGuideStep4Desc,
        targetWidgetName: 'ContentPlanList',
        checked: plans.isNotEmpty,
        status: plans.isEmpty
            ? localizations.mktGuideStatusNoPlans
            : localizations.mktGuideStatusPlans(plans.length),
      ),
      _GuideStep(
        id: 'masterContent',
        icon: Icons.auto_awesome,
        title: localizations.mktGuideStep5Title,
        description: localizations.mktGuideStep5Desc,
        targetWidgetName: 'MasterContentList',
        checked: approved.isNotEmpty,
        status: contents.isEmpty
            ? localizations.mktGuideStatusNoContent
            : approved.isEmpty
                ? localizations.mktGuideStatusNotApproved(contents.length)
                : localizations.mktGuideStatusApproved(
                    approved.length,
                    contents.length,
                  ),
      ),
      _GuideStep(
        id: 'adapt',
        icon: Icons.alt_route,
        title: localizations.mktGuideStep6Title,
        description: localizations.mktGuideStep6Desc,
        targetWidgetName: 'SocialPostList',
        checked: posts.isNotEmpty,
        status: posts.isEmpty
            ? localizations.mktGuideStatusNoVariants
            : localizations.mktGuideStatusVariants(posts.length),
      ),
      _GuideStep(
        id: 'publish',
        icon: Icons.send,
        title: localizations.mktGuideStep7Title,
        description: localizations.mktGuideStep7Desc,
        targetWidgetName: 'SocialPostList',
        checked: published.isNotEmpty,
        status: published.isEmpty
            ? localizations.mktGuideStatusNotPublished
            : localizations.mktGuideStatusPublished(published.length),
      ),
      _GuideStep(
        id: 'engagements',
        icon: Icons.thumb_up,
        title: localizations.mktGuideStep8Title,
        description: localizations.mktGuideStep8Desc,
        targetWidgetName: 'SocialEngagementList',
        optional: true,
        status: _statusOfOpened('engagements', localizations),
      ),
    ];
  }

  /// Status of a step that is completed by opening it.
  String _statusOfOpened(String id, MarketingLocalizations localizations) =>
      _completed.contains(id)
          ? localizations.mktGuideStatusOpened
          : localizations.mktGuideStatusNotOpened;

  @override
  Widget build(BuildContext context) {
    final localizations = MarketingLocalizations.of(context)!;
    final personaState = context.watch<PersonaBloc>().state;
    final planState = context.watch<ContentPlanBloc>().state;
    final contentState = context.watch<MasterContentBloc>().state;
    final postState = context.watch<SocialPostBloc>().state;
    final steps = _steps(
      localizations,
      personaState,
      planState,
      contentState,
      postState,
    );

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
      key: const Key('MarketingSetupGuide'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizations.mktGuideTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (widget.staticMenuConfig == null &&
                              guideItem?.menuItemId != null)
                            IconButton(
                              key: const Key('hideGuide'),
                              icon: const Icon(Icons.visibility_off),
                              tooltip: localizations.mktGuideHide,
                              onPressed: () => _confirmHideGuide(localizations),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.mktGuideIntro,
                        key: const Key('guideIntro'),
                        style: Theme.of(context).textTheme.bodyMedium,
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
  Widget _stepScreen(MarketingLocalizations localizations, _GuideStep step) {
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
                  Text(localizations.mktGuideBackToGuide),
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
    MarketingLocalizations localizations,
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
                  localizations.mktGuideNotAvailable,
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
                                '(${localizations.mktGuideOptional})',
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
