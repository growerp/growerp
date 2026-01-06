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
import 'package:growerp_user_company/growerp_user_company.dart';
import 'router_builder.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  runApp(
    CoreApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
    ),
  );
}

class CoreApp extends StatefulWidget {
  const CoreApp({
    super.key,
    required this.restClient,
    required this.classificationId,
    required this.chatClient,
    required this.notificationClient,
  });

  final RestClient restClient;
  final String classificationId;
  final WsClient chatClient;
  final WsClient notificationClient;

  @override
  State<CoreApp> createState() => _CoreAppState();
}

class _CoreAppState extends State<CoreApp> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'core_example');
  }

  @override
  void dispose() {
    // Close WebSocket connections gracefully to avoid backend ClosedChannelException
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
        builder: (context, state) {
          GoRouter router;

          if (state.status == MenuConfigStatus.success &&
              state.menuConfiguration != null) {
            // Use simplified config - no accounting submenu
            router = createDynamicAppRouter(
              [state.menuConfiguration!],
              config: DynamicRouterConfig(
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: 'Core Example',
                dashboardFabBuilder: (menuConfig) => Builder(
                  builder: (fabContext) => FloatingActionButton(
                    key: const Key('coreFab'),
                    heroTag: 'menuFab',
                    tooltip: 'Manage Menu Items',
                    onPressed: () {
                      showDialog(
                        context: fabContext,
                        builder: (dialogContext) => BlocProvider.value(
                          value: fabContext.read<MenuConfigBloc>(),
                          child: MenuItemListDialog(
                            menuConfiguration: menuConfig,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.menu),
                  ),
                ),
              ),
            );
          } else {
            // Loading or error, show splash screen using shared component
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, routeState) => AppSplashScreen.simple(
                    appTitle: 'GrowERP Core Example',
                    appId: 'core_example',
                  ),
                ),
              ],
            );
          }

          return TopApp(
            // Key forces complete rebuild when menu options change,
            // ensuring the new GoRouter with updated routes takes effect
            key: ValueKey(
              '${state.menuConfiguration?.menuConfigurationId ?? ''}_'
              '${state.menuConfiguration?.menuItems.length ?? 0}',
            ),
            restClient: widget.restClient,
            classificationId: widget.classificationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'Core Example',
            router: router,
            extraDelegates: const [UserCompanyLocalizations.delegate],
            extraBlocProviders: [
              ...getUserCompanyBlocProviders(
                widget.restClient,
                widget.classificationId,
              ),
            ],
            widgetRegistrations: coreWidgetRegistrations,
          );
        },
      ),
    );
  }
}
