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
import 'package:models/@models.dart';
import 'package:core/widgets/@widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:core/templates/@templates.dart';
import 'package:core/acctMenuItem_data.dart';

class AccountingForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) {
        Authenticate authenticate = state.authenticate;
        return DisplayMenuList(
          menuList: acctMenuItems,
          menuIndex: 0,
          actions: <Widget>[
            IconButton(
                key: Key('aboutButton'),
                icon: Image.asset('assets/images/about.png'),
                tooltip: 'About',
                onPressed: () => {
                      Navigator.pushNamed(context, '/about'),
                    }),
            if (authenticate.apiKey != null)
              IconButton(
                  key: Key('logoutButton'),
                  icon: Icon(Icons.do_not_disturb),
                  tooltip: 'Logout',
                  onPressed: () => {
                        BlocProvider.of<AuthBloc>(context).add(Logout()),
                      }),
          ],
        );
      }
      return LoadingIndicator();
    });
  }
}

class AcctDashBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    late Authenticate authenticate;
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) {
        authenticate = state.authenticate;
        return Container(
            padding: EdgeInsets.symmetric(
                vertical: isPhone ? 0.8 : 20, horizontal: isPhone ? 0.8 : 20),
            child: GridView.count(
              crossAxisCount: isPhone ? 2 : 3,
              padding: EdgeInsets.all(3.0),
              children: <Widget>[
                makeDashboardItem(
                  context,
                  acctMenuItems[1],
                  "Sls open inv: "
                      "${authenticate.company!.currencyId} "
                      "${authenticate.stats!.salesInvoicesNotPaidAmount ?? '0.00'} "
                      "(${authenticate.stats!.salesInvoicesNotPaidCount})",
                  "",
                  "",
                  "",
                ),
                makeDashboardItem(
                  context,
                  acctMenuItems[2],
                  "Pur unp inv: "
                      "${authenticate.company!.currencyId} "
                      "${authenticate.stats!.purchInvoicesNotPaidAmount ?? '0.00'} "
                      "(${authenticate.stats!.purchInvoicesNotPaidCount})",
                  "",
                  "",
                  "",
                ),
                makeDashboardItem(
                  context,
                  acctMenuItems[3],
                  "Accounts",
                  "Transactions",
                  "",
                  "",
                ),
/*                  makeDashboardItem(
                    context,
                    acctMenuItems[4],
                    "",
                    "",
                    "",
                    "",
                  ),
*/
              ],
            ));
      } else
        return Container();
    });
  }
}
