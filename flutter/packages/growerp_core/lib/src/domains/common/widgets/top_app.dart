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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../api_repository.dart';
import '../../../services/chat_server.dart';
import '../../../styles/color_schemes.dart';
import '../../domains.dart';
import '../../../l10n/generated/core_localizations.dart';

class TopApp extends StatelessWidget {
  TopApp({
    Key? key,
    required this.dbServer,
    required this.chatServer,
    this.title = 'GrowERP',
    required this.router,
    required this.menuOptions,
    this.extraDelegates = const [],
    this.blocProviders = const [],
  }) : super(key: key);

  final APIRepository dbServer;
  final ChatServer chatServer;
  final String title;
  final Route<dynamic> Function(RouteSettings) router;
  final List<MenuOption> menuOptions;
  final List<LocalizationsDelegate> extraDelegates;
  final List<BlocProvider> blocProviders;

  final List<LocalizationsDelegate> localizationsDelegates = [
    CoreLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider(create: (context) => dbServer),
            RepositoryProvider(create: (context) => chatServer),
          ],
          child: MultiBlocProvider(
              providers: [
                if (blocProviders.isNotEmpty)
                  BlocProvider<ThemeBloc>(
                      create: (context) => ThemeBloc()..add(ThemeSwitch())),
                BlocProvider<AuthBloc>(
                    create: (context) => AuthBloc(APIRepository(), ChatServer())
                      ..add(AuthLoad())),
              ],
              child: Builder(builder: (context) {
                return MultiBlocProvider(
                    // this list cannot be empty
                    providers: blocProviders.isNotEmpty
                        ? blocProviders
                        : [
                            BlocProvider<ThemeBloc>(
                                create: (context) =>
                                    ThemeBloc()..add(ThemeSwitch()))
                          ],
                    child: BlocBuilder<ThemeBloc, ThemeState>(
                        builder: (context, state) {
                      localizationsDelegates.addAll(extraDelegates);
                      return GestureDetector(
                          // close keyboard
                          onTap: () {
                            final currentFocus = FocusScope.of(context);

                            if (!currentFocus.hasPrimaryFocus) {
                              currentFocus.unfocus();
                            }
                          },
                          child: MaterialApp(
                              title: title,
                              supportedLocales: const [
                                Locale('en'),
                                Locale('th')
                              ],
                              debugShowCheckedModeBanner: false,
                              localizationsDelegates: localizationsDelegates,
                              builder: (context, child) =>
                                  ResponsiveBreakpoints.builder(
                                      child: child!,
                                      breakpoints: [
                                        const Breakpoint(
                                            start: 0, end: 500, name: MOBILE),
                                        const Breakpoint(
                                            start: 451, end: 800, name: TABLET),
                                        const Breakpoint(
                                            start: 801,
                                            end: 1920,
                                            name: DESKTOP),
                                        const Breakpoint(
                                            start: 1921,
                                            end: double.infinity,
                                            name: '4K'),
                                      ]),
                              themeMode: state.themeMode,
                              theme: ThemeData(
                                  useMaterial3: true,
                                  colorScheme: lightColorScheme),
                              darkTheme: ThemeData(
                                  useMaterial3: true,
                                  colorScheme: darkColorScheme),
                              onGenerateRoute: router,
                              home: BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  switch (state.status) {
                                    case AuthStatus.loading:
                                      return const SplashForm();
                                    case AuthStatus.changeIp:
                                      return const ChangeIpForm();
                                    default:
                                      return HomeForm(
                                          menuOptions: menuOptions,
                                          title: title);
                                  }
                                },
                              )));
                    }));
              })));
}
