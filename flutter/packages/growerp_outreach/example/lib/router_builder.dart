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
GoRouter createOutreachExampleRouter() {
  return createStaticAppRouter(
    menuConfig: outreachMenuConfig,
    appTitle: 'GrowERP Outreach Example',
    dashboard: const OutreachDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/campaigns' => const CampaignListScreen(),
      '/messages' => const OutreachMessageList(),
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
