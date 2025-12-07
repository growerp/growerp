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
      menuOptionItemId: 'WEB_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuItem(
      menuOptionItemId: 'WEB_WEBSITE',
      title: 'Website',
      route: '/website',
      iconName: 'web',
      sequenceNum: 20,
    ),
  ],
);

/// Creates a static go_router for the website example app
GoRouter createWebsiteExampleRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      if (!isAuthenticated && state.uri.path != '/') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          if (authState.status == AuthStatus.authenticated) {
            return const DisplayMenuOption(
              menuConfiguration: websiteMenuConfig,
              menuIndex: 0,
              child: WebsiteDashboard(),
            );
          } else {
            return const HomeForm(
              menuConfiguration: websiteMenuConfig,
              title: 'GrowERP Website Example',
            );
          }
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DisplayMenuOption(
            menuConfiguration: websiteMenuConfig,
            menuIndex: 1,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/website',
            builder: (context, state) => const WebsiteDialog(),
          ),
        ],
      ),
    ],
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

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 1,
            itemBuilder: (context, index) {
              return const _DashboardCard(
                title: 'Website',
                iconName: 'web',
                route: '/website',
                stats: 'Manage website settings',
              );
            },
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String route;
  final String stats;

  const _DashboardCard({
    required this.title,
    required this.iconName,
    required this.route,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getIconFromRegistry(iconName) ??
                  const Icon(Icons.dashboard, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stats,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
