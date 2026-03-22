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

/// Admin dashboard content - displays dashboard panels with statistics.
/// This is the content-only version for use with ShellRoute.
///
/// Tile sizing is driven by [MenuItem.tileType]:
/// - 'navigation' (default) → 1×1
/// - 'statistic' → 2×1 (shows stats text)
/// - 'graphic' → 2×2 (shows chart widget)
///
/// Any tile whose route is matched by [chartBuilder] is automatically
/// upgraded to 'graphic' type — no backend config change required.
class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

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
                onRefresh: () async {
                  context.read<AuthBloc>().add(AuthLoad());
                },
                // Provide the revenue/expense mini-chart for the accounting tile.
                // DashboardGrid auto-upgrades it to full-width 4-row graphic tile.
                chartBuilder: (route) {
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
