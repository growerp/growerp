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

/// Admin dashboard content - displays dashboard panels with statistics
/// This is the content-only version for use with ShellRoute
class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          builder: (context, menuState) {
            // Use menu configuration from bloc if available
            final menuConfig = menuState.menuConfiguration;

            if (menuConfig == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get dashboard items from menu configuration (top-level, active items only)
            // Exclude the Main/Dashboard item itself (route '/'), About, and sub-items
            // Top-level items don't have routes starting with /accounting/ (those are sub-items)
            final dashboardOptions =
                menuConfig.menuItems
                    .where(
                      (option) =>
                          option.isActive &&
                          option.route != null &&
                          option.route != '/' &&
                          option.route != '/about' &&
                          // Exclude accounting sub-items (they start with /accounting/)
                          !(option.route!.startsWith('/accounting/') &&
                              option.route != '/accounting'),
                    )
                    .toList()
                  ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: DashboardGrid(
                itemCount: dashboardOptions.length,
                itemBuilder: (context, index) {
                  final option = dashboardOptions[index];
                  return DashboardCard(
                    title: option.title,
                    iconName: option.iconName ?? 'dashboard',
                    route: option.route,
                    stats: getStatsForRoute(option.route, stats),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
