/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License. See the LICENSE.md file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'package:growerp_adk/growerp_adk.dart';

class MarketingDbForm extends StatelessWidget {
  const MarketingDbForm({super.key});

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

            final dashboardOptions =
                menuConfig.menuItems
                    .where(
                      (option) =>
                          option.isActive &&
                          option.route != null &&
                          option.route != '/' &&
                          option.route != '/about',
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
                onRefresh: () async {
                  context.read<AuthBloc>().add(AuthLoad());
                },
                compactGraphicRoutes: const {
                  '/marketing',
                  '/outreach',
                  '/crm',
                  '/agent-control',
                  '/orders',
                },
                chartBuilder: (route) {
                  if (route == '/marketing') {
                    return const MarketingDashboardChartMini();
                  }
                  if (route == '/outreach') {
                    return const OutreachDashboardChartMini();
                  }
                  if (route == '/crm') {
                    return const CrmDashboardChartMini();
                  }
                  if (route == '/agent-control') {
                    return const AgentControlDashboardChartMini();
                  }
                  if (route == '/orders') {
                    return const OrderDashboardChartMini(showPurchase: false);
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
