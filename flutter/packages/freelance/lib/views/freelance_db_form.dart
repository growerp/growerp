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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_activity/growerp_activity.dart';

class FreelanceDbForm extends StatelessWidget {
  const FreelanceDbForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          builder: (context, menuState) {
            final menuConfig = menuState.menuConfiguration;

            if (menuConfig == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Top-level active items, excluding the root '/', '/about',
            // and accounting sub-items (those starting with /accounting/)
            final dashboardOptions =
                menuConfig.menuItems
                    .where(
                      (option) =>
                          option.isActive &&
                          option.route != null &&
                          option.route != '/' &&
                          option.route != '/about' &&
                          !(option.route!.startsWith('/accounting/') &&
                              option.route != '/accounting'),
                    )
                    .toList()
                  ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: DashboardGrid(
                items: dashboardOptions,
                stats: stats,
                onToggleMinimize: (id) => context
                    .read<MenuConfigBloc>()
                    .add(MenuItemToggleMinimize(id)),
                compactGraphicRoutes: const {
                  '/tasks',
                  '/crm',
                  '/marketing',
                  '/outreach',
                  '/catalog',
                  '/orders',
                  '/acct-sales',
                  '/acct-purchase',
                  '/acct-ledger',
                },
                chartBuilder: (route) {
                  if (route == '/tasks') {
                    return const TaskDashboardChartMini();
                  }
                  if (route == '/crm') {
                    return const CrmDashboardChartMini();
                  }
                  if (route == '/marketing') {
                    return const MarketingDashboardChartMini();
                  }
                  if (route == '/outreach') {
                    return const OutreachDashboardChartMini();
                  }
                  if (route == '/catalog') {
                    return const CatalogDashboardChartMini();
                  }
                  if (route == '/orders') {
                    return const OrderDashboardChartMini();
                  }
                  if (route == '/acct-sales') {
                    return const AcctSalesDashboardChartMini();
                  }
                  if (route == '/acct-purchase') {
                    return const AcctPurchaseDashboardChartMini();
                  }
                  if (route == '/acct-ledger') {
                    return const LedgerDashboardChartMini();
                  }
                  if (route == '/acct-reports' ||
                      route == '/accounting' ||
                      route == '/accounting/reports') {
                    return const RevenueExpenseChartMini();
                  }
                  return null;
                },
              ),
            );
          },
        );
      },
    );
  }
}
