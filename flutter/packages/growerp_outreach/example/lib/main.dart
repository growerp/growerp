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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_marketing/growerp_marketing.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  runApp(
    TopApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP Outreach Example',
      router: createOutreachExampleRouter(),
      extraDelegates: const [
        UserCompanyLocalizations.delegate,
      ],
      extraBlocProviders: [
        BlocProvider<OutreachCampaignBloc>(
          create: (context) => OutreachCampaignBloc(restClient),
        ),
        BlocProvider<OutreachMessageBloc>(
          create: (context) => OutreachMessageBloc(restClient),
        ),
        BlocProvider<PlatformConfigBloc>(
          create: (context) => PlatformConfigBloc(restClient),
        ),
        ...getUserCompanyBlocProviders(restClient, 'AppAdmin'),
        ...getMarketingBlocProviders(restClient, 'AppAdmin'),
      ],
    ),
  );
}

/// Static menu configuration
const outreachMenuConfig = MenuConfiguration(
  menuConfigurationId: 'OUTREACH_EXAMPLE',
  appId: 'outreach_example',
  name: 'Outreach Example Menu',
  menuItems: [
    MenuItem(
      menuOptionItemId: 'OUT_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
    ),
    MenuItem(
      menuOptionItemId: 'OUT_CAMPAIGNS',
      title: 'Campaigns',
      route: '/campaigns',
      iconName: 'campaign',
      sequenceNum: 20,
    ),
    MenuItem(
      menuOptionItemId: 'OUT_MESSAGES',
      title: 'Messages',
      route: '/messages',
      iconName: 'message',
      sequenceNum: 30,
    ),
    MenuItem(
      menuOptionItemId: 'OUT_AUTOMATION',
      title: 'Automation',
      route: '/automation',
      iconName: 'autorenew',
      sequenceNum: 40,
    ),
    MenuItem(
      menuOptionItemId: 'OUT_WEBSITE',
      title: 'Website',
      route: '/website',
      iconName: 'web',
      sequenceNum: 50,
    ),
    MenuItem(
      menuOptionItemId: 'OUT_LEADS',
      title: 'Leads',
      route: '/leads',
      iconName: 'people',
      sequenceNum: 60,
    ),
    MenuItem(
      menuOptionItemId: 'OUT_PLATFORMS',
      title: 'Platforms',
      route: '/platforms',
      iconName: 'settings',
      sequenceNum: 70,
    ),
  ],
);

/// Creates a static go_router for the outreach example app
GoRouter createOutreachExampleRouter() {
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
              menuConfiguration: outreachMenuConfig,
              menuIndex: 0,
              child: OutreachDashboard(),
            );
          } else {
            return const HomeForm(
              menuConfiguration: outreachMenuConfig,
              title: 'GrowERP Outreach Example',
            );
          }
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          int menuIndex = 0;
          final path = state.uri.path;
          for (int i = 0; i < outreachMenuConfig.menuItems.length; i++) {
            if (outreachMenuConfig.menuItems[i].route == path) {
              menuIndex = i;
              break;
            }
          }
          return DisplayMenuOption(
            menuConfiguration: outreachMenuConfig,
            menuIndex: menuIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignListScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const OutreachMessageList(),
          ),
          GoRoute(
            path: '/automation',
            builder: (context, state) => const AutomationScreen(),
          ),
          GoRoute(
            path: '/website',
            builder: (context, state) => const LandingPageList(),
          ),
          GoRoute(
            path: '/leads',
            builder: (context, state) => const UserList(
              key: Key('Lead'),
              role: Role.lead,
            ),
          ),
          GoRoute(
            path: '/platforms',
            builder: (context, state) => const PlatformConfigListScreen(),
          ),
        ],
      ),
    ],
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

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _DashboardCard(
                title: item.title,
                iconName: item.iconName ?? 'dashboard',
                route: item.route ?? '/',
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

  const _DashboardCard({
    required this.title,
    required this.iconName,
    required this.route,
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
            ],
          ),
        ),
      ),
    );
  }
}
