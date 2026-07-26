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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_website/growerp_website.dart';

/// Canonical menu configuration for Website example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const websiteMenuConfig = MenuConfiguration(
  menuConfigurationId: 'WEBSITE_EXAMPLE',
  appId: 'website_example',
  name: 'Website Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'WEB_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'WebsiteDashboard',
    ),
    MenuItem(
      itemKey: 'WEB_WEBSITE',
      title: 'Website',
      route: '/website',
      iconName: 'web',
      sequenceNum: 20,
      widgetName: 'WebsiteDialog',
    ),
  ],
);

/// Creates a static go_router for the website example app using shared helper.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createWebsiteExampleRouter() {
  return createStaticAppRouter(
    menuConfig: websiteMenuConfig,
    appTitle: 'GrowERP Website Example',
    dashboard: const WebsiteDashboard(),
    widgetBuilder: (route) => switch (route) {
      '/website' => const WebsiteDialog(),
      _ => const WebsiteDashboard(),
    },
  );
}

/// Simple dashboard for website example
class WebsiteDashboard extends StatelessWidget {
  const WebsiteDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        return const DashboardGrid(
          items: [
            MenuItem(
              menuItemId: 'website',
              title: 'Website',
              iconName: 'web',
              route: '/website',
            ),
          ],
        );
      },
    );
  }
}
