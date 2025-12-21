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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_models/growerp_models.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  Bloc.observer = AppBlocObserver();
  runApp(
    TopApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: "GrowERP Website Example",
      router: createWebsiteExampleRouter(),
      extraDelegates: const [WebsiteLocalizations.delegate],
      extraBlocProviders: getWebsiteBlocProviders(restClient),
    ),
  );
}

/// Static menu configuration
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

/// Creates a static go_router for the website example app using shared helper
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

        return DashboardGrid(
          itemCount: 1,
          itemBuilder: (context, index) {
            return const DashboardCard(
              title: 'Website',
              iconName: 'web',
              route: '/website',
              stats: 'Manage website settings',
            );
          },
        );
      },
    );
  }
}
