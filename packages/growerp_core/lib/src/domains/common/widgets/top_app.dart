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
import 'package:flutter_phoenix/generated/i18n.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:responsive_framework/utils/scroll_behavior.dart';

import '../../../api_repository.dart';
import '../../../services/chat_server.dart';
import '../../../styles/themes.dart';
import '../../domains.dart';

class TopApp extends StatelessWidget {
  const TopApp(
      {Key? key,
      required this.dbServer,
      required this.chatServer,
      this.title = 'GrowERP',
      required this.router,
      required this.menuOptions})
      : super(key: key);

  final APIRepository dbServer;
  final ChatServer chatServer;
  final String title;
  final Route<dynamic> Function(RouteSettings) router;
  final List<MenuOption> menuOptions;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (context) => dbServer),
          RepositoryProvider(create: (context) => chatServer),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
                create: (context) =>
                    AuthBloc(dbServer, chatServer)..add(AuthLoad())),
            BlocProvider<ChatRoomBloc>(
              create: (context) =>
                  ChatRoomBloc(dbServer, chatServer, context.read<AuthBloc>())
                    ..add(ChatRoomFetch()),
            ),
            BlocProvider<ChatMessageBloc>(
                create: (context) => ChatMessageBloc(
                    dbServer, chatServer, context.read<AuthBloc>())),
          ],
          child: MyApp(title, router, menuOptions),
        ),
      );
}

class MyApp extends StatelessWidget {
  final String title;
  final Route<dynamic> Function(RouteSettings) router;
  final List<MenuOption> menuOptions;
  const MyApp(this.title, this.router, this.menuOptions, {super.key});

  @override
  Widget build(BuildContext context) {
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
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            builder: (context, widget) => ResponsiveWrapper.builder(
                BouncingScrollWrapper.builder(context, widget!),
                maxWidth: 2460,
                defaultScale: true,
                breakpoints: [
                  const ResponsiveBreakpoint.resize(450, name: MOBILE),
                  const ResponsiveBreakpoint.autoScale(800, name: TABLET),
                  const ResponsiveBreakpoint.resize(1200, name: DESKTOP),
                  const ResponsiveBreakpoint.autoScale(2460, name: '4K'),
                ],
                background: Container(color: const Color(0xFFF5F5F5))),
            theme: Themes.formTheme,
            onGenerateRoute: router,
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state.status == AuthStatus.failure) {
                  return const FatalErrorForm('server connection problem');
                }
                if (state.status == AuthStatus.authenticated) {
                  return HomeForm(
                      message: state.message,
                      menuOptions: menuOptions,
                      title: title);
                }
                if (state.status == AuthStatus.unAuthenticated) {
                  return HomeForm(
                      message: state.message,
                      menuOptions: menuOptions,
                      title: title);
                }
                if (state.status == AuthStatus.changeIp) return ChangeIpForm();
                return SplashForm();
              },
            )));
  }
}
