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
import 'package:backend/ofbiz.dart';
import 'package:backend/moqui.dart';
import 'package:core/styles/themes.dart';
import 'package:core/widgets/@widgets.dart';
import 'generated/l10n.dart';
import 'hotelRouter.dart' as router;
import 'forms/@forms.dart';
import 'package:core/forms/@forms.dart' as core;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("app_settings");
  Bloc.observer = SimpleBlocObserver();
  final Object repos = GlobalConfiguration().getValue("backend") == 'moqui'
      ? Moqui(client: Dio())
      : Ofbiz(client: Dio());
  runApp(RepositoryProvider(
    create: (context) => repos,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<CategoryBloc>(create: (context) => CategoryBloc(repos)),
        BlocProvider<ProductBloc>(create: (context) => ProductBloc(repos)),
        BlocProvider<AssetBloc>(create: (context) => AssetBloc(repos)),
        BlocProvider<AdminBloc>(
            create: (context) => UserBloc(repos, "GROWERP_M_ADMIN")),
        BlocProvider<EmployeeBloc>(
            create: (context) => UserBloc(repos, "GROWERP_M_EMPLOYEE")),
        BlocProvider<CustomerBloc>(
            create: (context) => UserBloc(repos, "GROWERP_M_CUSTOMER")),
        BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(repos)..add(LoadAuth())),
        BlocProvider<SalesOrderBloc>(
            create: (context) => FinDocBloc(repos, true, 'order')),
        BlocProvider<SalesCartBloc>(
            create: (context) => CartBloc(
                repos: repos,
                sales: true,
                finDocBloc:
                    BlocProvider.of<SalesOrderBloc>(context) as FinDocBloc)),
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
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        builder: (context, widget) => ResponsiveWrapper.builder(
            BouncingScrollWrapper.builder(context, widget!),
            maxWidth: 1200,
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
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthProblem)
              return core.FatalErrorForm("Internet or server problem?");
            if (state is AuthUnauthenticated) {
              if (state.authenticate?.company == null) {
                return core.RegisterForm(
                    'No companies found in system, create one?');
              } else
                return HomeForm();
            }
            if (state is AuthAuthenticated) return HomeForm();
            return core.SplashForm();
          },
        ));
  }
}
