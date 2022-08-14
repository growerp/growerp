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
import 'package:core/api_repository.dart';
import 'package:core/services/chat_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hotel/menuItem_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'generated/l10n.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:core/styles/themes.dart';
import 'router.dart' as router;
import 'package:http/http.dart' as http;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:core/domains/domains.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset("app_settings");
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  // can change backend url by pressing long the title on the home screen.
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String ip = prefs.getString('ip') ?? '';
  String chat = prefs.getString('chat') ?? '';
  String singleCompany = prefs.getString('companyPartyId') ?? '';
  if (ip.isNotEmpty) {
    late http.Response response;
    try {
      response = await http.get(Uri.parse('${ip}rest/s1/growerp/Ping'));
      if (response.statusCode == 200) {
        GlobalConfiguration().updateValue('databaseUrl', ip);
        GlobalConfiguration().updateValue('chatUrl', chat);
        GlobalConfiguration().updateValue('singleCompany', singleCompany);
        print('=== New ip: $ip , chat: $chat company: $singleCompany Updated!');
      }
    } catch (error) {
      print('===$ip does not respond...not updating databaseUrl: $error');
    }
  }

  BlocOverrides.runZoned(
    () => runApp(Phoenix(
        child: TopApp(dbServer: APIRepository(), chatServer: ChatServer()))),
    blocObserver: AppBlocObserver(),
  );
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
            create: (context) => ChatRoomBloc(
                dbServer, chatServer, BlocProvider.of<AuthBloc>(context))
              ..add(ChatRoomFetch()),
          ),
          BlocProvider<ChatMessageBloc>(
              create: (context) => ChatMessageBloc(
                  dbServer, chatServer, BlocProvider.of<AuthBloc>(context))),
        ],
        child: MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  static String title = "GrowERP Hotel";
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        // close keyboard
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: MaterialApp(
            title: title,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            builder: (context, widget) => ResponsiveWrapper.builder(
                BouncingScrollWrapper.builder(context, widget!),
                maxWidth: 2460,
                minWidth: 450,
                defaultScale: true,
                breakpoints: [
                  ResponsiveBreakpoint.resize(450, name: MOBILE),
                  ResponsiveBreakpoint.autoScale(800, name: TABLET),
                  ResponsiveBreakpoint.resize(1200, name: DESKTOP),
                  ResponsiveBreakpoint.autoScale(2460, name: "4K"),
                ],
                background: Container(color: Color(0xFFF5F5F5))),
            theme: Themes.formTheme,
            onGenerateRoute: router.generateRoute,
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state.status == AuthStatus.failure)
                  return FatalErrorForm("server connection problem");
                if (state.status == AuthStatus.authenticated)
                  return HomeForm(
                      message: state.message,
                      menuOptions: menuOptions,
                      title: title);
                if (state.status == AuthStatus.unAuthenticated)
                  return HomeForm(
                      message: state.message,
                      menuOptions: menuOptions,
                      title: title);
                if (state.status == AuthStatus.changeIp) return ChangeIpForm();
                return SplashForm();
              },
            )));
  }
}
