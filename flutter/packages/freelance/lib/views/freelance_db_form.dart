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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:universal_io/io.dart';

import '../menu_options.dart';

class FreelanceDbForm extends StatelessWidget {
  const FreelanceDbForm({super.key});

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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Authenticate authenticate = state.authenticate!;
          return DashBoardForm(
            dashboardItems: [
              makeDashboardItem(
                'dbCompany',
                context,
                getMenuOptions(context)[1],
                [
                  authenticate.company!.name!.length > 20
                      ? "${authenticate.company!.name!.substring(0, 20)}..."
                      : "${authenticate.company!.name}",
                  "All open tasks: ${authenticate.stats?.allTasks ?? 0}",
                  "Not Invoiced hours: ${authenticate.stats?.notInvoicedHours ?? 0}",
                ],
              ),
              makeDashboardItem('dbCrm', context, getMenuOptions(context)[2], [
                "All Opportunities: ${authenticate.stats?.opportunities ?? 0}",
                "My Opportunities: ${authenticate.stats?.myOpportunities ?? 0}",
                "Leads: ${authenticate.stats?.leads ?? 0}",
                "Customers: ${authenticate.stats?.customers ?? 0}",
              ]),
              makeDashboardItem(
                'dbCatalog',
                context,
                getMenuOptions(context)[3],
                [
                  "Categories: ${authenticate.stats?.categories ?? 0}",
                  "Products: ${authenticate.stats?.products ?? 0}",
                  "Assets: ${authenticate.stats?.products ?? 0}",
                ],
              ),
              makeDashboardItem(
                'dbOrders',
                context,
                getMenuOptions(context)[4],
                [
                  "Sales Orders: ${authenticate.stats?.openSlsOrders ?? 0}",
                  "Customers: ${authenticate.stats?.customers ?? 0}",
                  "Purchase Orders: ${authenticate.stats?.openPurOrders ?? 0}",
                  "Suppliers: ${authenticate.stats?.suppliers ?? 0}",
                ],
              ),
              makeDashboardItem(
                'dbAccounting',
                context,
                getMenuOptions(context)[6],
                [
                  "Sales open invoices: \n"
                      "$currencySymbol "
                      "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
                      "(${authenticate.stats?.salesInvoicesNotPaidCount ?? 0})",
                  "Purchase unpaid invoices: \n"
                      "$currencySymbol "
                      "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
                      "(${authenticate.stats?.purchInvoicesNotPaidCount ?? 0})",
                ],
              ),
              makeDashboardItem(
                'dbInventory',
                context,
                getMenuOptions(context)[5],
                [],
              ),
            ],
          );
        }
        return const LoadingIndicator();
      },
    );
  }
}
