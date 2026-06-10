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
    AdkApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
    ),
  );
}

/// Standalone GrowERP ADK application — composes the growerp_adk building
/// block (agents, jobs, chat, governance) on top of growerp_core.
class AdkApp extends StatefulWidget {
  const AdkApp({
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
  State<AdkApp> createState() => _AdkAppState();
}

class _AdkAppState extends State<AdkApp> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, 'adk_example');
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
            router = createDynamicAdkRouter(
              [state.menuConfiguration!],
              menuConfigBloc: menuConfigBloc,
            );
          } else {
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, routeState) => AppSplashScreen.simple(
                    appTitle: 'GrowERP ADK',
                    appId: 'adk_example',
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
            classificationId: widget.classificationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: 'GrowERP ADK',
            router: router,
            extraDelegates: const [UserCompanyLocalizations.delegate],
            extraBlocProviders: [
              ...getUserCompanyBlocProviders(
                widget.restClient,
                widget.classificationId,
              ),
            ],
            widgetRegistrations: adkWidgetRegistrations,
          );
        },
      ),
    );
  }
}
