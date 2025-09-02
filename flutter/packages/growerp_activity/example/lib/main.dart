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

import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'router.dart' as router;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  RestClient restClient = RestClient(await buildDioClient());

  String classificationId = GlobalConfiguration().get("classificationId");
  Bloc.observer = AppBlocObserver();

  runApp(
    TopApp(
      restClient: RestClient(await buildDioClient()),
      classificationId: GlobalConfiguration().get("classificationId"),
      chatClient: WsClient('chat'),
      notificationClient: WsClient('notws'),
      title: 'GrowERP Activity Management: ToDo, Event, ....',
      router: router.generateRoute,
      menuOptions: menuOptions,
      extraDelegates: extraDelegates,
      extraBlocProviders: getExampleBlocProviders(restClient, classificationId),
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
    child: const MainMenuForm(),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'To Do',
    route: '/todos',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const ActivityList(ActivityType.todo),
  ),
  MenuOption(
    image: 'packages/growerp_core/images/crmGrey.png',
    selectedImage: 'packages/growerp_core/images/crm.png',
    title: 'Events',
    route: '/events',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const ActivityList(ActivityType.event),
  ),
];

// main menu
class MainMenuForm extends StatelessWidget {
  const MainMenuForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Authenticate authenticate = state.authenticate!;
          return DashBoardForm(
            dashboardItems: [
              makeDashboardItem('dbTodo', context, menuOptions[1], [
                "To Do: ${authenticate.stats?.todoActivities ?? 0}",
              ]),
              makeDashboardItem('dbEvent', context, menuOptions[2], [
                "Events: ${authenticate.stats?.eventActivities ?? 0}",
              ]),
            ],
          );
        }

        return const LoadingIndicator();
      },
    );
  }
}

List<LocalizationsDelegate<dynamic>> extraDelegates = const [
  UserCompanyLocalizations.delegate,
];

List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  return [...getUserCompanyBlocProviders(restClient, classificationId)];
}
