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
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// Canonical menu configuration for Outreach example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const outreachMenuConfig = MenuConfiguration(
  menuConfigurationId: 'OUTREACH_EXAMPLE',
  appId: 'outreach_example',
  name: 'Outreach Example Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'OUT_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'OutreachDashboard',
    ),
    MenuItem(
      menuItemId: 'OUT_GUIDE',
      title: 'Guide',
      route: '/guide',
      iconName: 'checklist',
      sequenceNum: 15,
      widgetName: 'OutreachSetupGuideScreen',
    ),
    MenuItem(
      menuItemId: 'OUT_CAMPAIGNS',
      title: 'Campaigns',
      route: '/campaigns',
      iconName: 'rocket_launch',
      sequenceNum: 20,
      widgetName: 'CampaignListScreen',
    ),
    MenuItem(
      menuItemId: 'OUT_MESSAGES',
      title: 'Messages',
      route: '/messages',
      iconName: 'outbox',
      sequenceNum: 30,
      widgetName: 'OutreachMessageList',
    ),
    MenuItem(
      menuItemId: 'OUT_SEND_QUEUE',
      title: 'Send Queue',
      route: '/sendQueue',
      iconName: 'send',
      sequenceNum: 35,
      widgetName: 'LinkedInSendQueueScreen',
    ),
    MenuItem(
      menuItemId: 'OUT_AUTOMATION',
      title: 'Automation',
      route: '/automation',
      iconName: 'smart_toy',
      sequenceNum: 40,
      widgetName: 'AutomationScreen',
    ),
    MenuItem(
      menuItemId: 'OUT_WEBSITE',
      title: 'Landing Page',
      route: '/website',
      iconName: 'web',
      sequenceNum: 50,
      widgetName: 'LandingPageList',
    ),
    MenuItem(
      menuItemId: 'OUT_LEADS',
      title: 'Leads',
      route: '/leads',
      iconName: 'person_search',
      sequenceNum: 60,
      widgetName: 'UserList',
    ),
    MenuItem(
      menuItemId: 'OUT_PLATFORMS',
      title: 'Platforms',
      route: '/platforms',
      iconName: 'hub',
      sequenceNum: 70,
      widgetName: 'PlatformConfigListScreen',
    ),
  ],
);

/// Creates a static go_router for the outreach example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
/// Localization delegates for the outreach example app and its tests.
const List<LocalizationsDelegate> outreachExampleDelegates = [
  UserCompanyLocalizations.delegate,
  OutreachLocalizations.delegate,
  MarketingLocalizations.delegate,
];

GoRouter createOutreachExampleRouter() {
  return createStaticAppRouter(
    menuConfig: outreachMenuConfig,
    appTitle: 'GrowERP Outreach Example',
    dashboard: const OutreachDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/guide' =>
        const OutreachSetupGuideScreen(staticMenuConfig: outreachMenuConfig),
      '/campaigns' => const CampaignListScreen(),
      '/messages' => const OutreachMessageList(),
      '/sendQueue' => const LinkedInSendQueueScreen(),
      '/automation' => const AutomationScreen(),
      '/website' => const LandingPageList(),
      '/leads' => const UserList(key: Key('Lead'), role: Role.lead),
      '/platforms' => const PlatformConfigListScreen(),
      _ => const OutreachDashboard(),
    },
  );
}

/// Simple dashboard for outreach example
class OutreachDashboard extends StatelessWidget {
  const OutreachDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final items = outreachMenuConfig.menuItems
            .where((item) => item.route != '/')
            .toList();

        return DashboardGrid(items: items);
      },
    );
  }
}
