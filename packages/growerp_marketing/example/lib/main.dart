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

import 'package:growerp_core/api_repository.dart';
import 'package:growerp_core/services/chat_server.dart';
import 'menuOption_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:responsive_framework/responsive_framework.dart';
import 'generated/l10n.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/styles/themes.dart';
import 'router.dart' as router;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:growerp_core/domains/domains.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');
  Bloc.observer = AppBlocObserver();
  runApp(Phoenix(
      child: TopApp(dbServer: APIRepository(), chatServer: ChatServer())));
}

class TopApp extends StatelessWidget {
  const TopApp({Key? key, required this.dbServer, required this.chatServer})
      : super(key: key);

  final APIRepository dbServer;
  final ChatServer chatServer;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
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
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  static String title = 'GrowERP administrator.';

  const MyApp({super.key});
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
            onGenerateRoute: router.generateRoute,
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
