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

class AdminDbForm extends StatelessWidget {
  const AdminDbForm({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: DashBoardForm(
            dashboardItems: [
              makeDashboardItem('dbCompany', context, menuOptions(context)[1], [
                authenticate.company!.name!.length > 20
                    ? "${authenticate.company!.name!.substring(0, 20)}..."
                    : "${authenticate.company!.name}",
                "${localizations.administrators}: ${authenticate.stats?.admins ?? 0}",
                "${localizations.otherEmployees}: ${authenticate.stats?.employees ?? 0}",
              ]),
              makeDashboardItem('dbCrm', context, menuOptions(context)[2], [
                "${localizations.allOpportunities}: ${authenticate.stats?.opportunities ?? 0}",
                "${localizations.leads}: ${authenticate.stats?.leads ?? 0}",
                "${localizations.customers}: ${authenticate.stats?.customers ?? 0}",
              ]),
              makeDashboardItem('dbCatalog', context, menuOptions(context)[3], [
                "${localizations.categories}: ${authenticate.stats?.categories ?? 0}",
                "${localizations.products}: ${authenticate.stats?.products ?? 0}",
                "${localizations.assets}: ${authenticate.stats?.assets ?? 0}",
              ]),
              makeDashboardItem('dbOrders', context, menuOptions(context)[4], [
                "${localizations.salesOrders}: ${authenticate.stats?.openSlsOrders ?? 0}",
                "${localizations.customers}: ${authenticate.stats?.customers ?? 0}",
                "${localizations.purchaseOrders}: ${authenticate.stats?.openPurOrders ?? 0}",
                "${localizations.suppliers}: ${authenticate.stats?.suppliers ?? 0}",
              ]),
              makeDashboardItem('dbInventory', context, menuOptions(context)[5], [
                "${localizations.incomingShipments}: ${authenticate.stats?.incomingShipments ?? 0}",
                "${localizations.outgoingShipments}: ${authenticate.stats?.outgoingShipments ?? 0}",
                "${localizations.whLocations}: ${authenticate.stats?.whLocations ?? 0}",
              ]),
              makeDashboardItem('dbAccounting', context, menuOptions(context)[6], [
                "${localizations.salesOpenInvoices}:",
                "$currencySymbol "
                    "${authenticate.stats?.salesInvoicesNotPaidAmount ?? '0.00'} "
                    "(${authenticate.stats?.salesInvoicesNotPaidCount ?? 0})",
                "${localizations.purchaseUnpaidInvoices}:",
                "$currencySymbol "
                    "${authenticate.stats?.purchInvoicesNotPaidAmount ?? '0.00'} "
                    "(${authenticate.stats?.purchInvoicesNotPaidCount ?? 0})",
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
