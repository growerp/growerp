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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'router_builder.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String applicationId = GlobalConfiguration().get("applicationId");

  // Check for a production/test backend url override. Side effect: sets the
  // "test" flag so the top-left test banner shows (same as the admin app).
  await getBackendUrlOverride(applicationId, packageInfo.version);

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  runApp(
    AgentsApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
    ),
  );
}

/// GrowERP Agents application — AI agents + governance (chat, jobs, approvals,
/// action audit) plus organization (company, employees, website) and system
/// setup, on the dynamic (backend-driven) menu so options can be customised.
class AgentsApp extends StatefulWidget {
  const AgentsApp({
    super.key,
    required this.restClient,
    required this.applicationId,
    required this.chatClient,
    required this.notificationClient,
  });

  final RestClient restClient;
  final String applicationId;
  final WsClient chatClient;
  final WsClient notificationClient;

  @override
  State<AgentsApp> createState() => _AgentsAppState();
}

class _AgentsAppState extends State<AgentsApp> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'agents');
  }

  @override
  void dispose() {
    widget.chatClient.close();
    widget.notificationClient.close();
    _menuConfigBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _menuConfigBloc,
      child: BlocBuilder<MenuConfigBloc, MenuConfigState>(
        buildWhen: (previous, current) {
          if (previous.menuConfiguration == null &&
              current.menuConfiguration != null) {
            return true;
          }
          if (previous.menuConfiguration?.menuConfigurationId !=
              current.menuConfiguration?.menuConfigurationId) {
            return true;
          }
          if ((previous.menuConfiguration?.menuItems.length ?? 0) !=
              (current.menuConfiguration?.menuItems.length ?? 0)) {
            return true;
          }
          final prevItems = previous.menuConfiguration?.menuItems ?? [];
          final currItems = current.menuConfiguration?.menuItems ?? [];
          for (int i = 0; i < prevItems.length && i < currItems.length; i++) {
            if (prevItems[i].menuItemId != currItems[i].menuItemId ||
                prevItems[i].route != currItems[i].route ||
                prevItems[i].widgetName != currItems[i].widgetName ||
                prevItems[i].isActive != currItems[i].isActive ||
                prevItems[i].title != currItems[i].title) {
              return true;
            }
          }
          return false;
        },
        builder: (context, state) {
          GoRouter router;
          if (state.status == MenuConfigStatus.success &&
              state.menuConfiguration != null) {
            final menuConfigBloc = context.read<MenuConfigBloc>();
            router = createDynamicAgentsRouter(
              [state.menuConfiguration!],
              menuConfigBloc: menuConfigBloc,
            );
          } else {
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, routeState) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Agents',
                    appId: 'agents',
                  ),
                ),
                GoRoute(
                  path: '/:path',
                  builder: (context, routeState) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Agents',
                    appId: 'agents',
                  ),
                ),
              ],
            );
          }

          return TopApp(
            key: ValueKey(
              '${state.menuConfiguration?.menuConfigurationId ?? ''}_'
              '${state.menuConfiguration?.menuItems.length ?? 0}',
            ),
            restClient: widget.restClient,
            applicationId: widget.applicationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'GrowERP Agents',
            router: router,
            extraDelegates: delegates,
            extraBlocProviders: getAgentsBlocProviders(
              widget.restClient,
              widget.applicationId,
            ),
            widgetRegistrations: agentsWidgetRegistrations,
          );
        },
      ),
    );
  }
}

List<LocalizationsDelegate> delegates = const [
  UserCompanyLocalizations.delegate,
  WebsiteLocalizations.delegate,
];

List<BlocProvider> getAgentsBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, applicationId),
    ...getWebsiteBlocProviders(restClient),
  ];
}
