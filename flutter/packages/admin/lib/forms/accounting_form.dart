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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../acct_menu_options.dart';

class AccountingForm extends StatelessWidget {
  const AccountingForm({super.key});

  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    return DashBoardForm(
      key: const Key('AcctDashBoard'),
      dashboardItems: [
        makeDashboardItem('acctSales', context, acctMenuOptions[1], [
          "Sls open inv: "
              "${authenticate.company!.currency!.description} "
              "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
              "(${authenticate.stats?.salesInvoicesNotPaidCount})",
        ]),
        makeDashboardItem('acctPurchase', context, acctMenuOptions[2], [
          "Pur unp inv: "
              "${authenticate.company!.currency!.description} "
              "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
              "(${authenticate.stats?.purchInvoicesNotPaidCount})",
        ]),
        makeDashboardItem('acctLedger', context, acctMenuOptions[3],
            ["Accounts", "Transactions", "Journal"]),
        makeDashboardItem('acctReports', context, acctMenuOptions[4], [
          "Balance Sheet",
          "Balance summary",
        ]),
        makeDashboardItem('AcctSetup', context, acctMenuOptions[5],
            ["Time Periods", "Item Types", "Payment Types"]),
        makeDashboardItem('Main dashboard', context, acctMenuOptions[6], []),
      ],
    );
  }
}
