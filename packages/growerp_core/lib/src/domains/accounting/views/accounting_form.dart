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
import '../../../acct_menu_option_data.dart';
import '../../../templates/@templates.dart';
import '../../../domains/domains.dart';

class AccountingForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.authenticated) {
//        Authenticate authenticate = state.authenticate;
        return DisplayMenuOption(
          menuList: acctMenuOptions,
          menuIndex: 0,
        );
      }
      return LoadingIndicator();
    });
  }
}

class AcctDashBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        Authenticate authenticate = state.authenticate!;
        return DashBoardForm(
          dashboardItems: [
            makeDashboardItem(
              'accntSales',
              context,
              acctMenuOptions[1],
              "Sls open inv: "
                  "${authenticate.company!.currency!.description} "
                  "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
                  "(${authenticate.stats?.salesInvoicesNotPaidCount})",
              "",
              "",
              "",
            ),
            makeDashboardItem(
              'accntPurchase',
              context,
              acctMenuOptions[2],
              "Pur unp inv: "
                  "${authenticate.company!.currency!.description} "
                  "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
                  "(${authenticate.stats?.purchInvoicesNotPaidCount})",
              "",
              "",
              "",
            ),
            makeDashboardItem(
              'accntLedger',
              context,
              acctMenuOptions[3],
              "Accounts",
              "Transactions",
              "",
              "",
            ),
            makeDashboardItem(
              'Main dashboard',
              context,
              acctMenuOptions[4],
              "",
              "",
              "",
              "",
            ),
          ],
        );
      }
      return LoadingIndicator();
    });
  }
}
