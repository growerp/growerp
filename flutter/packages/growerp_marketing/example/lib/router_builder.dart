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
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';

/// Canonical menu configuration for Marketing example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const marketingMenuConfig = MenuConfiguration(
  menuConfigurationId: 'MARKETING_EXAMPLE',
  appId: 'marketing_example',
  name: 'Marketing Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'MKT_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'MarketingDashboard',
    ),
    MenuItem(
      itemKey: 'MKT_PERSONAS',
      title: 'Personas',
      route: '/personas',
      iconName: 'people',
      sequenceNum: 50,
      widgetName: 'PersonaList',
    ),
    MenuItem(
      itemKey: 'MKT_CONTENT',
      title: 'Content Plans',
      route: '/contentPlans',
      iconName: 'calendar_today',
      sequenceNum: 60,
      widgetName: 'ContentPlanList',
    ),
    MenuItem(
      itemKey: 'MKT_CONTENT_HUB',
      title: 'Content',
      route: '/masterContent',
      iconName: 'auto_awesome',
      sequenceNum: 65,
      widgetName: 'MasterContentList',
    ),
    // Social Posts are primarily managed as platform variants inside a
    // Content piece; this direct entry keeps the standalone CRUD screen
    // reachable (and navigable for the social post integration test).
    MenuItem(
      itemKey: 'MKT_SOCIAL',
      title: 'Social Posts',
      route: '/socialPosts',
      iconName: 'share',
      sequenceNum: 70,
      widgetName: 'SocialPostList',
    ),
  ],
);

/// Creates a static go_router for the marketing example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
/// Localization delegates for the marketing example app and its tests.
const List<LocalizationsDelegate> marketingExampleDelegates = [
  MarketingLocalizations.delegate,
];

GoRouter createMarketingExampleRouter() {
  return createStaticAppRouter(
    menuConfig: marketingMenuConfig,
    appTitle: 'GrowERP Marketing Example',
    dashboard: const MarketingDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/personas' => const PersonaList(),
      '/contentPlans' => const ContentPlanList(),
      '/masterContent' => const MasterContentList(),
      '/socialPosts' => const SocialPostList(),
      _ => const MarketingDashboard(),
    },
  );
}

/// BLoC providers for the marketing example app.
///
/// Used by both the production app (main.dart) and all integration tests.
List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [...getMarketingBlocProviders(restClient, applicationId)];
}

/// Simple dashboard for marketing example
class MarketingDashboard extends StatelessWidget {
  const MarketingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final items = marketingMenuConfig.menuItems
            .where((item) => item.route != '/')
            .toList();

        return DashboardGrid(items: items);
      },
    );
  }
}
