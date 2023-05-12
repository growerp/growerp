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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("app_settings");

  BlocOverrides.runZoned(
      () => runApp(TopApp(dbServer: APIRepository(), chatServer: ChatServer())),
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
              create: (context) => UserBloc(dbServer, UserGroup.customer,
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
        builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
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
