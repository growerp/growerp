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
import 'package:intl/intl.dart';
import 'package:universal_io/io.dart';

import '../acct_menu_options.dart';

class AccountingForm extends StatelessWidget {
  const AccountingForm({super.key});

  @override
  Widget build(BuildContext context) {
    String currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
    String currencySymbol = NumberFormat.simpleCurrency(
      locale: Platform.localeName,
      name: currencyId,
    ).currencySymbol;
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    List<MenuOption> acctOptions = getAcctMenuOptions(context);
    return DashBoardForm(
      key: const Key('AcctDashBoard'),
      dashboardItems: [
        makeDashboardItem('acctSales', context, acctOptions[1], [
          CoreLocalizations.of(context)!.openInvoices,
          "$currencySymbol "
              "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
              "(${authenticate.stats?.salesInvoicesNotPaidCount})",
        ]),
        makeDashboardItem('acctPurchase', context, acctOptions[2], [
          CoreLocalizations.of(context)!.openInvoices,
          "$currencySymbol "
              "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
              "(${authenticate.stats?.purchInvoicesNotPaidCount})",
        ]),
        makeDashboardItem('acctLedger', context, acctOptions[3], []),
        makeDashboardItem('acctReports', context, acctOptions[4], [
          CoreLocalizations.of(context)!.revenueExpense,
          CoreLocalizations.of(context)!.balanceSheet,
          CoreLocalizations.of(context)!.balanceSummary,
        ]),
        makeDashboardItem('AcctSetup', context, acctOptions[5], [
          CoreLocalizations.of(context)!.timePeriods,
          CoreLocalizations.of(context)!.itemTypes,
          CoreLocalizations.of(context)!.paymentTypes,
        ]),
        makeDashboardItem(
          CoreLocalizations.of(context)!.mainDashboard,
          context,
          acctOptions[6],
          [],
        ),
      ],
    );
  }
}
