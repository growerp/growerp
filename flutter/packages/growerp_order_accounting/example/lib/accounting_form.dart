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
import 'acct_menu_option_data.dart';
import 'package:growerp_models/growerp_models.dart';

class AccountingForm extends StatelessWidget {
  const AccountingForm({super.key});

  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    final acctOptions = acctMenuOptions(context);
    return DashBoardForm(
      key: const Key('AcctDashBoard'),
      dashboardItems: [
        makeDashboardItem('acctSales', context, acctOptions[1], [
          "Sls open inv: "
              "${authenticate.company!.currency!.description} "
              "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
              "(${authenticate.stats?.salesInvoicesNotPaidCount})",
        ]),
        makeDashboardItem('acctPurchase', context, acctOptions[2], [
          "Pur unp inv: "
              "${authenticate.company!.currency!.description} "
              "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
              "(${authenticate.stats?.purchInvoicesNotPaidCount})",
        ]),
        makeDashboardItem('acctLedger', context, acctOptions[3], [
          "Accounts",
          "Transactions",
          "Journals",
        ]),
        makeDashboardItem('reports', context, acctOptions[4], [
          "Balance Sheet",
          "Balance summary",
        ]),
        makeDashboardItem('AcctSetup', context, acctOptions[5], [
          "Time Periods",
          "Item Types",
          "Payment Types",
        ]),
        makeDashboardItem('Main dashboard', context, acctOptions[6], []),
      ],
    );
  }
}
