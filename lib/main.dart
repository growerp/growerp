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

import 'package:core/widgets/@widgets.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/forms/@forms.dart';
import 'package:core/styles/themes.dart';
import 'package:models/@models.dart';
import 'router.dart' as router;
import 'forms/@forms.dart' as local;
import 'package:backend/@backend.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("app_settings");
  Bloc.observer = SimpleBlocObserver();

  String backend = GlobalConfiguration().getValue("backend");
  var repos = backend == 'moqui'
      ? Moqui(client: Dio())
//      : backend == 'ofbiz'
//          ? Ofbiz(client: Dio())
      : null;

  runApp(Ecommerce(repos: repos!));
}

class Ecommerce extends StatelessWidget {
  const Ecommerce({
    Key? key,
    required this.repos,
  }) : super(key: key);

  final Object repos;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repos,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CategoryBloc>(create: (_) => CategoryBloc(repos)),
          BlocProvider<ProductBloc>(create: (_) => ProductBloc(repos)),
          BlocProvider<SalesOrderBloc>(
              create: (context) => FinDocBloc(repos, true, 'order')),
          BlocProvider<CustomerBloc>(
              create: (context) => UserBloc(repos, "GROWERP_M_CUSTOMER")),
          BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(repos)..add(LoadAuth())),
          BlocProvider<SalesCartBloc>(
              create: (context) => CartBloc(
                  repos: repos,
                  sales: true,
                  finDocBloc:
                      BlocProvider.of<SalesOrderBloc>(context) as FinDocBloc)
                ..add(LoadCart(
                    FinDoc(sales: true, docType: 'order', items: [])))),
        ],
        child: MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          if (state is AuthProblem)
            return FatalErrorForm("Internet or server problem?");
          if (state is AuthUnauthenticated &&
              state.authenticate.company == null)
            return FatalErrorForm("No company found in system\n"
                "Go to the admin app to create one!");
          if (state is AuthAuthenticated)
            return local.HomeForm(message: state.message);
          if (state is AuthUnauthenticated)
            return local.HomeForm(message: state.message);
          return SplashForm();
        }));
  }
}
