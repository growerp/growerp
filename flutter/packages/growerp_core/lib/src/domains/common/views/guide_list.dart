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

import 'package:growerp_core/growerp_core.dart';

/// Guides tab of System Setup: the step-by-step guides this app was built
/// with, whether each is shown in the menu, and a way to open one here.
///
/// A guide is any registered screen whose widget name ends with
/// [_guideSuffix]; packages add one by registering such a widget, nothing has
/// to be listed here.
const String _guideSuffix = 'GuideScreen';

class GuideList extends StatefulWidget {
  const GuideList({super.key});

  @override
  State<GuideList> createState() => _GuideListState();
}

class _GuideListState extends State<GuideList> {
  /// Widget name of the guide opened inside this screen, null on the index.
  String? _openGuide;

  /// Menu item of [widgetName] when the running app has one, so the switch
  /// below knows whether the guide can be shown in the menu at all.
  MenuItem? _menuItemFor(String widgetName) {
    MenuConfiguration? config;
    try {
      config = context.watch<MenuConfigBloc>().state.menuConfiguration;
    } catch (_) {
      return null;
    }
    for (final item in config?.menuItems ?? <MenuItem>[]) {
      if (item.widgetName == widgetName) return item;
      for (final child in item.children ?? <MenuItem>[]) {
        if (child.widgetName == widgetName) return child;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    final guides =
        WidgetRegistry.allMetadata
            .where((m) => m.widgetName.endsWith(_guideSuffix))
            .toList()
          ..sort((a, b) => a.widgetName.compareTo(b.widgetName));

    if (_openGuide != null) return _guidePage(localizations, _openGuide!);

    if (guides.isEmpty) {
      return Center(
        key: const Key('guideList'),
        child: Text(localizations.noGuidesAvailable),
      );
    }

    return ListView.builder(
      key: const Key('guideList'),
      padding: const EdgeInsets.all(16),
      itemCount: guides.length,
      itemBuilder: (context, index) => _guideCard(localizations, guides[index]),
    );
  }

  Widget _guideCard(CoreLocalizations localizations, WidgetMetadata guide) {
    final menuItem = _menuItemFor(guide.widgetName);
    return Card(
      key: Key('guide_${guide.widgetName}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading:
                getIconByName(guide.iconName) ?? const Icon(Icons.checklist),
            title: Text(guide.description),
            subtitle: Text(guide.widgetName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _openGuide = guide.widgetName),
          ),
          // Only a guide that is in the menu can be hidden from it.
          if (menuItem != null)
            SwitchListTile(
              key: Key('showGuide_${guide.widgetName}'),
              title: Text(localizations.showOutreachGuide),
              subtitle: Text(localizations.showOutreachGuideHelp),
              value: menuItem.isActive,
              onChanged: (value) => context.read<MenuConfigBloc>().add(
                MenuWidgetVisibilitySet(
                  widgetName: guide.widgetName,
                  hidden: !value,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The opened guide with a bar on top returning to the index.
  Widget _guidePage(CoreLocalizations localizations, String widgetName) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('guidePage'),
      children: [
        Material(
          color: theme.colorScheme.secondaryContainer,
          child: InkWell(
            key: const Key('backToGuideList'),
            onTap: () => setState(() => _openGuide = null),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: 8),
                  Text(localizations.guides),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          // Keyed with the widget name, same as the router does, so the
          // opened guide is discoverable by tests.
          child: KeyedSubtree(
            key: Key(widgetName),
            child: WidgetRegistry.getWidget(widgetName),
          ),
        ),
      ],
    );
  }
}
