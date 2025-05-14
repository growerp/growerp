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

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../get_core_bloc_providers.dart';
import '../../../services/ws_client.dart';
import '../../domains.dart';
import '../../../l10n/generated/core_localizations.dart';

class TopApp extends StatelessWidget {
  TopApp({
    super.key,
    required this.restClient,
    required this.classificationId,
    required this.chatClient,
    required this.notificationClient,
    this.title = '',
    required this.router,
    required this.menuOptions,
    this.extraDelegates = const [],
    this.extraBlocProviders = const [],
    this.screens = const {},
    this.company,
  });

  final RestClient restClient;
  final String classificationId;
  final Map<String, Widget> screens; // string to widget translation
  final Company? company;

  final WsClient chatClient;
  final WsClient notificationClient;
  final String title;
  final Route<dynamic> Function(RouteSettings) router;
  final List<MenuOption> menuOptions;
  final List<LocalizationsDelegate> extraDelegates;
  final List<BlocProvider> extraBlocProviders;
  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  final List<LocalizationsDelegate> localizationsDelegates = [
    CoreLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (context) => restClient),
          RepositoryProvider(create: (context) => chatClient),
          RepositoryProvider(create: (context) => notificationClient),
          RepositoryProvider(create: (context) => classificationId),
          RepositoryProvider(create: (context) => screens),
          RepositoryProvider(create: (context) => company),
        ],
        child: MultiBlocProvider(
            providers: [
              ...getCoreBlocProviders(restClient, chatClient,
                  notificationClient, classificationId, screens, company),
              ...extraBlocProviders
            ],
            child:
                BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
              localizationsDelegates.addAll(extraDelegates);
              return GestureDetector(
                  onTap: () {
                    FocusScopeNode currentFocus = FocusScope.of(context);

                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                  },
                  child: MaterialApp(
                      navigatorKey: _rootNavigatorKey,
                      title: title,
                      supportedLocales: const [Locale('en'), Locale('th')],
                      scrollBehavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.touch,
                        },
                      ),
                      debugShowCheckedModeBanner:
                          GlobalConfiguration().get("test"),
                      localizationsDelegates: localizationsDelegates,
                      builder: (context, child) => ResponsiveBreakpoints
                              .builder(child: child!, breakpoints: [
                            const Breakpoint(start: 0, end: 500, name: MOBILE),
                            const Breakpoint(
                                start: 451, end: 800, name: TABLET),
                            const Breakpoint(
                                start: 801, end: 1920, name: DESKTOP),
                            const Breakpoint(
                                start: 1921, end: double.infinity, name: '4K'),
                          ]),
                      themeMode: state.themeMode,
                      theme: FlexThemeData.light(
                        scheme: FlexScheme.jungle,
                        subThemesData: const FlexSubThemesData(
                          dialogBackgroundSchemeColor:
                              SchemeColor.outlineVariant,
                          inputDecoratorBorderType:
                              FlexInputBorderType.underline,
                        ),
                        useMaterial3: true,
                      ),
                      darkTheme: FlexThemeData.dark(
                        scheme: FlexScheme.jungle,
                        subThemesData: const FlexSubThemesData(
                          dialogBackgroundSchemeColor:
                              SchemeColor.outlineVariant,
                          inputDecoratorBorderType:
                              FlexInputBorderType.underline,
                        ),
                        useMaterial3: true,
                      ),
                      onGenerateRoute: router,
                      navigatorObservers: [AppNavObserver()],
                      home: BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          switch (state.status) {
                            case AuthStatus.failure:
                              HelperFunctions.showMessage(
                                  context, '${state.message}', Colors.red);
                              break;
                            default:
                              HelperFunctions.showMessage(
                                  context, state.message, Colors.green);
                          }
                        },
                        builder: (context, state) {
                          switch (state.status) {
                            case AuthStatus.initial:
                            case AuthStatus.loading:
                              return Scaffold(
                                  // scaffold need for messages
                                  backgroundColor: Colors.transparent,
                                  body: Container());
                            default:
                              return HomeForm(
                                  menuOptions: menuOptions, title: title);
                          }
                        },
                      )));
            })));
  }
}
