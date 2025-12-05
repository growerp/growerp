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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      router: generateRoute,
      menuOptions: (context) => menuOptions,
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

// Menu definition
List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const OutreachDashboard(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'Campaigns',
    route: '/campaigns',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const CampaignListScreen(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'Messages',
    route: '/messages',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const OutreachMessageList(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'Automation',
    route: '/automation',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const AutomationScreen(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/productsGrey.png',
    selectedImage: 'packages/growerp_core/images/products.png',
    title: 'Website',
    route: '/website',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const LandingPageList(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/supplierGrey.png',
    selectedImage: 'packages/growerp_core/images/supplier.png',
    title: 'Leads',
    route: '/leads',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const UserList(
      key: Key('Lead'),
      role: Role.lead,
    ),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/setupGrey.png',
    selectedImage: 'packages/growerp_core/images/setup.png',
    title: 'Platforms',
    route: '/platforms',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const PlatformConfigListScreen(),
  ),
];

// routing
Route<dynamic> generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    debugPrint(
      '>>>NavigateTo { ${settings.name} '
      'with: ${settings.arguments.toString()} }',
    );
  }
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (context) => HomeForm(menuOptions: (c) => menuOptions),
      );
    case '/campaigns':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions,
          menuIndex: 1,
        ),
      );
    case '/messages':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions,
          menuIndex: 2,
        ),
      );
    case '/automation':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions,
          menuIndex: 3,
        ),
      );
    case '/website':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions,
          menuIndex: 4,
        ),
      );
    case '/leads':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions,
          menuIndex: 5,
        ),
      );
    case '/platforms':
      return MaterialPageRoute(
        builder: (context) => DisplayMenuOption(
          menuList: menuOptions,
          menuIndex: 6,
        ),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => FatalErrorForm(
          message: "Routing not found for request: ${settings.name}",
        ),
      );
  }
}

/// Simple dashboard for outreach example
class OutreachDashboard extends StatelessWidget {
  const OutreachDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          return DashBoardForm(
            dashboardItems: [
              makeDashboardItem('dbCampaigns', context, menuOptions[1], [
                'Campaigns',
                'Manage outreach campaigns',
                'Track performance',
              ]),
              makeDashboardItem('dbMessages', context, menuOptions[2], [
                'Messages',
                'View sent messages',
                'Track responses',
              ]),
              makeDashboardItem('dbAutomation', context, menuOptions[3], [
                'Manage workflows',
              ]),
              makeDashboardItem('dbWebsite', context, menuOptions[4], [
                'Website',
                'Manage landing pages',
                'Track visitors',
              ]),
              makeDashboardItem('dbLeads', context, menuOptions[5], [
                'Leads',
                'View generated leads',
                'Manage contacts',
              ]),
              makeDashboardItem('dbPlatforms', context, menuOptions[6], [
                'Platforms',
                'Manage platform configs',
                'Set daily limits',
              ]),
            ],
          );
        }
        return const LoadingIndicator();
      },
    );
  }
}
