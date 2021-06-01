/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:backend/moqui.dart';
import 'package:core/styles/themes.dart';
import 'package:core/widgets/@widgets.dart';
import 'generated/l10n.dart';
import 'hotelRouter.dart' as router;
import 'forms/@forms.dart';
import 'package:core/forms/@forms.dart' as core;
import 'package:flutter_driver/driver_extension.dart';

void main() async {
  // enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("app_settings");
  Bloc.observer = SimpleBlocObserver();

  String backend = GlobalConfiguration().getValue("backend");
  var repos = backend == 'moqui'
      ? Moqui(client: Dio())
//      : backend == 'ofbiz'
//          ? Ofbiz(client: Dio())
      : null;

  runApp(HotelApp(repos: repos!));
}

class HotelApp extends StatelessWidget {
  const HotelApp({
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
          BlocProvider<CategoryBloc>(create: (context) => CategoryBloc(repos)),
          BlocProvider<ProductBloc>(create: (context) => ProductBloc(repos)),
          BlocProvider<AssetBloc>(
              create: (context) => AssetBloc(repos)..add(FetchAsset())),
          BlocProvider<AdminBloc>(
              create: (context) => UserBloc(repos, "GROWERP_M_ADMIN")),
          BlocProvider<EmployeeBloc>(
              create: (context) => UserBloc(repos, "GROWERP_M_EMPLOYEE")),
          BlocProvider<CustomerBloc>(
              create: (context) => UserBloc(repos, "GROWERP_M_CUSTOMER")),
          BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(repos)..add(LoadAuth())),
          BlocProvider<SalesOrderBloc>(
              create: (context) =>
                  FinDocBloc(repos, true, 'order')..add(FetchFinDoc())),
          BlocProvider<AccntBloc>(create: (context) => AccntBloc(repos)),
          BlocProvider<TransactionBloc>(
              create: (context) => FinDocBloc(repos, false, 'transaction')),
          BlocProvider<SalesInvoiceBloc>(
              create: (context) => FinDocBloc(repos, true, 'invoice')),
          BlocProvider<PurchInvoiceBloc>(
              create: (context) => FinDocBloc(repos, false, 'invoice')),
          BlocProvider<SalesPaymentBloc>(
              create: (context) => FinDocBloc(repos, true, 'payment')),
          BlocProvider<PurchPaymentBloc>(
              create: (context) => FinDocBloc(repos, false, 'payment')),
        ],
        // add other blocs here
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
            if (state is AuthProblem)
              return core.FatalErrorForm("Internet or server problem?");
            if (state is AuthAuthenticated)
              return HomeForm(message: state.message);
            if (state is AuthUnauthenticated)
              return HomeForm(message: state.message);
            return core.SplashForm();
          },
        ));
  }
}
