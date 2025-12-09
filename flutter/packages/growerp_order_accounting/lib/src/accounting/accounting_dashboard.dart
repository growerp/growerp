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
import 'package:responsive_framework/responsive_framework.dart';

/// A reusable accounting dashboard widget that displays accounting menu options
/// as cards with statistics. This widget can be used across different apps
/// (admin, freelance, hotel, etc.) by specifying the appropriate menu option prefix.
///
/// Example usage:
/// ```dart
/// AccountingDashboard(menuOptionPrefix: 'ADMIN_ACC_')
/// AccountingDashboard(menuOptionPrefix: 'FREELANCE_ACC_')
/// ```
///
/// If no prefix is specified, it defaults to showing all accounting-related
/// menu options based on route pattern `/accounting/`.
class AccountingDashboard extends StatelessWidget {
  /// The prefix used to filter menu options from the MenuConfiguration.
  /// For example: 'ADMIN_ACC_', 'FREELANCE_ACC_', 'HOTEL_ACC_'
  final String? menuOptionPrefix;

  /// Optional floating action button to display
  final Widget? floatingActionButton;

  const AccountingDashboard({
    super.key,
    this.menuOptionPrefix,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.status != AuthStatus.authenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final authenticate = authState.authenticate!;
        final stats = authenticate.stats;
        final currency = authenticate.company?.currency?.description ?? '';

        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          builder: (context, menuState) {
            final menuConfig = menuState.menuConfiguration;

            // Get dashboard options based on prefix or route pattern
            List<MenuOption> dashboardOptions;

            if (menuConfig != null && menuOptionPrefix != null) {
              // Use menu configuration with prefix filtering
              dashboardOptions =
                  menuConfig.menuOptions
                      .where(
                        (option) =>
                            option.isActive &&
                            option.menuOptionId != null &&
                            option.menuOptionId!.startsWith(menuOptionPrefix!),
                      )
                      .toList()
                    ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));
            } else {
              // Fallback: show default accounting cards
              dashboardOptions = [];
            }

            // If we have menu options from config, use dynamic cards
            if (dashboardOptions.isNotEmpty) {
              return _buildDynamicDashboard(context, dashboardOptions, stats);
            }

            // Otherwise, use static cards with stats
            return _buildStaticDashboard(context, stats, currency);
          },
        );
      },
    );
  }

  Widget _buildDynamicDashboard(
    BuildContext context,
    List<MenuOption> options,
    Stats? stats,
  ) {
    return Scaffold(
      key: const Key('AcctDashBoard'),
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
            childAspectRatio: 1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return DashboardCard(
              title: option.title,
              iconName: option.iconName ?? 'accounting',
              route: option.route,
              stats: _getStatsForAccountingRoute(option.route, stats),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStaticDashboard(
    BuildContext context,
    Stats? stats,
    String currency,
  ) {
    return Scaffold(
      key: const Key('AcctDashBoard'),
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.count(
          crossAxisCount: ResponsiveBreakpoints.of(context).isMobile ? 2 : 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            DashboardCard(
              title: "Sales",
              iconName: 'attach_money',
              route: '/accounting/sales',
              stats:
                  "Open Inv: $currency ${stats?.salesInvoicesNotPaidAmount ?? '0.00'}\n(${stats?.salesInvoicesNotPaidCount ?? 0})",
            ),
            DashboardCard(
              title: "Purchase",
              iconName: 'money_off',
              route: '/accounting/purchase',
              stats:
                  "Unpaid Inv: $currency ${stats?.purchInvoicesNotPaidAmount ?? '0.00'}\n(${stats?.purchInvoicesNotPaidCount ?? 0})",
            ),
            const DashboardCard(
              title: "Sales Payments",
              iconName: 'input',
              route: '/accounting/sales_payments',
              stats: "Payments",
            ),
            const DashboardCard(
              title: "Purchase Payments",
              iconName: 'output',
              route: '/accounting/purchase_payments',
              stats: "Payments",
            ),
            const DashboardCard(
              title: "Ledger",
              iconName: 'account_balance_wallet',
              route: '/accounting/ledger',
              stats: "Accounts, Trans, Journals",
            ),
            const DashboardCard(
              title: "Reports",
              iconName: 'summarize',
              route: '/accounting/reports',
              stats: "Balance Sheet, Summary",
            ),
            const DashboardCard(
              title: "Setup",
              iconName: 'settings',
              route: '/accounting/setup',
              stats: "Periods, Item types, Payment types",
            ),
          ],
        ),
      ),
    );
  }

  /// Maps accounting sub-routes to their corresponding statistics
  String? _getStatsForAccountingRoute(String? route, Stats? stats) {
    if (stats == null || route == null) return null;

    if (route.contains('sales')) {
      return 'Invoices: ${stats.salesInvoicesNotPaidCount}';
    } else if (route.contains('purchase')) {
      return 'Invoices: ${stats.purchInvoicesNotPaidCount}';
    } else if (route.contains('ledger')) {
      return 'Accounts, Trans, Journals';
    } else if (route.contains('reports')) {
      return 'Balance Sheet, Summary';
    } else if (route.contains('setup')) {
      return 'Periods, Types';
    }
    return null;
  }
}
