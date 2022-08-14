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
import 'package:core/domains/domains.dart';
import 'package:core/services/chat_server.dart';
import 'package:core/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'router.dart' as router;
import 'forms/@forms.dart' as local;
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("app_settings");

  BlocOverrides.runZoned(
      () => runApp(Phoenix(
          child: TopApp(dbServer: APIRepository(), chatServer: ChatServer()))),
      blocObserver: AppBlocObserver());
}

class TopApp extends StatelessWidget {
  const TopApp({Key? key, required this.dbServer, required this.chatServer})
      : super(key: key);

  final APIRepository dbServer;
  final ChatServer chatServer;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: dbServer,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
              lazy: false,
              create: (context) =>
                  AuthBloc(dbServer, chatServer)..add(AuthLoad())),
          BlocProvider<SalesOrderBloc>(
              create: (context) =>
                  FinDocBloc(dbServer, true, FinDocType.order)),
          BlocProvider<CustomerBloc>(
              create: (context) => UserBloc(dbServer, UserGroup.Customer,
                  BlocProvider.of<AuthBloc>(context))),
          BlocProvider<SalesCartBloc>(
              create: (context) => CartBloc(
                  repos: context.read<APIRepository>(),
                  sales: true,
                  docType: FinDocType.order,
                  finDocBloc:
                      BlocProvider.of<SalesOrderBloc>(context) as FinDocBloc)
                ..add(CartFetch(FinDoc(
                    sales: true, docType: FinDocType.order, items: [])))),
        ],
        child: MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  static String title = 'GrowERP Ecommerce.';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        builder: (context, widget) => ResponsiveWrapper.builder(
            BouncingScrollWrapper.builder(context, widget!),
            maxWidth: 2460,
            minWidth: 450,
            defaultScale: true,
            breakpoints: [
              ResponsiveBreakpoint.resize(450, name: MOBILE),
              ResponsiveBreakpoint.autoScale(800, name: TABLET),
              ResponsiveBreakpoint.autoScale(1000, name: TABLET),
              ResponsiveBreakpoint.resize(1200, name: DESKTOP),
              ResponsiveBreakpoint.autoScale(2460, name: "4K"),
            ],
            background: Container(color: Color(0xFFF5F5F5))),
        theme: Themes.formTheme,
        onGenerateRoute: router.generateRoute,
        home: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
          if (state.status == AuthStatus.failure)
            return FatalErrorForm("Internet or server problem?");
          if (state.status == AuthStatus.unAuthenticated &&
              state.authenticate!.company == null)
            return FatalErrorForm("No company found in system\n"
                "Go to the admin app to create one!");
          if (state.status == AuthStatus.unAuthenticated ||
              state.status == AuthStatus.authenticated)
            return local.HomeForm(message: state.message);
          return SplashForm();
        }));
  }
}
