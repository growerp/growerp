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
import 'ledger/views/revenue_expense_chart_mini.dart';

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

  // Static MenuItem list shown when MenuConfigBloc is unavailable
  static const List<MenuItem> _staticMenuItems = [
    MenuItem(
      menuItemId: 'acc_sales',
      title: 'Sales',
      iconName: 'attach_money',
      route: '/accounting/sales',
      tileType: 'statistic',
    ),
    MenuItem(
      menuItemId: 'acc_purchase',
      title: 'Purchase',
      iconName: 'money_off',
      route: '/accounting/purchase',
      tileType: 'statistic',
    ),
    MenuItem(
      menuItemId: 'acc_sales_pay',
      title: 'Sales Payments',
      iconName: 'input',
      route: '/accounting/sales_payments',
    ),
    MenuItem(
      menuItemId: 'acc_purch_pay',
      title: 'Purchase Payments',
      iconName: 'output',
      route: '/accounting/purchase_payments',
    ),
    MenuItem(
      menuItemId: 'acc_ledger',
      title: 'Ledger',
      iconName: 'account_balance_wallet',
      route: '/accounting/ledger',
    ),
    MenuItem(
      menuItemId: 'acc_ledger_accts',
      title: 'Ledger Accounts',
      iconName: 'account_tree',
      route: '/accounting/ledger-accounts',
    ),
    MenuItem(
      menuItemId: 'acc_ledger_journal',
      title: 'Ledger Journal',
      iconName: 'receipt_long',
      route: '/accounting/ledger-journal',
    ),
    MenuItem(
      menuItemId: 'acc_reports',
      title: 'Revenue/Expenses',
      iconName: 'summarize',
      route: '/accounting/reports',
    ),
    MenuItem(
      menuItemId: 'acc_setup',
      title: 'Setup',
      iconName: 'settings',
      route: '/accounting/setup',
    ),
    MenuItem(
      menuItemId: 'acc_item_types',
      title: 'Item Types',
      iconName: 'list',
      route: '/accounting/setup/item-types',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc?>();
    if (authBloc == null) {
      return const Center(
        child: Text('AuthBloc not available. Please ensure it is provided.'),
      );
    }

    return BlocBuilder<AuthBloc, AuthState>(
      bloc: authBloc,
      builder: (context, authState) {
        if (authState.status != AuthStatus.authenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = authState.authenticate?.stats;
        final menuConfigBloc = context.read<MenuConfigBloc?>();

        if (menuConfigBloc == null) {
          return _buildGrid(context, _staticMenuItems, stats);
        }

        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          bloc: menuConfigBloc,
          builder: (context, menuState) {
            final menuConfig = menuState.menuConfiguration;

            List<MenuItem> items;
            if (menuConfig != null && menuOptionPrefix != null) {
              items =
                  menuConfig.menuItems
                      .where(
                        (o) =>
                            o.isActive &&
                            o.menuItemId != null &&
                            o.menuItemId!.startsWith(menuOptionPrefix!),
                      )
                      .toList()
                    ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));
            } else {
              items = [];
            }

            if (items.isEmpty) {
              return _buildGrid(context, _staticMenuItems, stats);
            }

            return _buildGrid(context, items, stats);
          },
        );
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<MenuItem> items,
    Stats? stats,
  ) {
    return Scaffold(
      key: const Key('AcctDashBoard'),
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: DashboardGrid(
        items: items,
        stats: stats,
        onToggleMinimize: (id) =>
            context.read<MenuConfigBloc?>()?.add(MenuItemToggleMinimize(id)),
        chartBuilder: (route) {
          if (route == '/accounting/reports') {
            return const RevenueExpenseChartMini();
          }
          return null;
        },
      ),
    );
  }
}
