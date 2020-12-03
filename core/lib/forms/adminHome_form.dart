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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:models/models.dart';
import 'package:core/helper_functions.dart';
import 'package:core/routing_constants.dart';
import 'package:core/widgets/@widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AdminHome extends StatelessWidget {
  final FormArguments formArguments;
  AdminHome(this.formArguments);

  @override
  Widget build(BuildContext context) {
    var a = (formArguments) => (DashBoard(formArguments?.message));
    return ShowNavigationRail(a(formArguments), 0);
  }
}

class DashBoard extends StatelessWidget {
  final String message;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  DashBoard([this.message]) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthProblem) {
        return Container(
            child: Center(
                child: Text("${state.errorMessage}",
                    style:
                        new TextStyle(fontSize: 18.0, color: Colors.black))));
      }
      if (state is AuthAuthenticated) {
        Authenticate authenticate = state.authenticate;
        return ScaffoldMessenger(
            key: scaffoldMessengerKey,
            child: Scaffold(
                appBar: AppBar(
                    automaticallyImplyLeading:
                        ResponsiveWrapper.of(context).isSmallerThan(TABLET),
                    title: companyLogo(context, authenticate,
                        authenticate?.company?.name ?? 'Company??'),
                    actions: <Widget>[
                      if (authenticate?.apiKey != null)
                        IconButton(
                            icon: Icon(Icons.do_not_disturb),
                            tooltip: 'Logout',
                            onPressed: () => {
                                  BlocProvider.of<AuthBloc>(context)
                                      .add(Logout()),
                                  Navigator.pushNamed(context, HomeRoute,
                                      arguments: FormArguments(
                                          "Successfully logged out."))
                                }),
                    ]),
                drawer: myDrawer(context, authenticate),
                body: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 20.0, horizontal: 2.0),
                  child: GridView.count(
                    crossAxisCount:
                        ResponsiveWrapper.of(context).isSmallerThan(TABLET)
                            ? 2
                            : 3,
                    padding: EdgeInsets.all(3.0),
                    children: <Widget>[
                      makeDashboardItem("DashBoard1", Icons.bubble_chart),
                      makeDashboardItem(
                          "DashBoard2", Icons.bubble_chart_outlined),
                      makeDashboardItem("DashBoard3", Icons.bubble_chart),
                      makeDashboardItem("DashBoard4", Icons.bar_chart_rounded),
                      makeDashboardItem("DashBoard5", Icons.bar_chart_outlined),
                      makeDashboardItem("DashBoard6", Icons.bar_chart)
                    ],
                  ),
                )));
      }
      if (state is AuthUnauthenticated) {
        Authenticate authenticate = state.authenticate;
        return ScaffoldMessenger(
            key: scaffoldMessengerKey,
            child: Scaffold(
                appBar: AppBar(
                    title: companyLogo(context, authenticate,
                        authenticate?.company?.name ?? 'Company??')),
                body: Center(
                    child: Column(children: <Widget>[
                  SizedBox(height: 150),
                  Text("Login with an existing Id"),
                  RaisedButton(
                    autofocus: true,
                    child: Text('Login'),
                    onPressed: () async {
                      dynamic result =
                          await Navigator.pushNamed(context, LoginRoute);
                      if (result)
                        Navigator.pushNamed(context, HomeRoute,
                            arguments:
                                FormArguments("Successfully logged in."));
                    },
                  ),
                  SizedBox(height: 50),
                  Text(
                      "Or create a new company and you being the administrator"),
                  RaisedButton(
                    child: Text('Create a new company and admin'),
                    onPressed: () {
                      authenticate.company.partyId = null;
                      Navigator.popAndPushNamed(context, RegisterRoute);
                    },
                  ),
                ]))));
      }
      return Container(child: Center(child: Text("Should never arrive here?")));
    });
  }
}

Card makeDashboardItem(String title, IconData icon) {
  return Card(
      elevation: 1.0,
      margin: new EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(220, 220, 220, 1.0)),
        child: new InkWell(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            verticalDirection: VerticalDirection.down,
            children: <Widget>[
              SizedBox(height: 50.0),
              Center(
                  child: Icon(
                icon,
                size: 40.0,
                color: Colors.black,
              )),
              SizedBox(height: 20.0),
              new Center(
                child: new Text(title,
                    style: new TextStyle(fontSize: 18.0, color: Colors.black)),
              )
            ],
          ),
        ),
      ));
}
