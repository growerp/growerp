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

/// Health dashboard content - displays dashboard panels with statistics
/// This is the content-only version for use with dynamic routing
class AdminDbForm extends StatelessWidget {
  const AdminDbForm({super.key});

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
            // Exclude the Main/Dashboard item itself (route '/')
            final dashboardItems =
                menuConfig.menuItems
                    .where(
                      (item) =>
                          item.isActive &&
                          item.route != '/' &&
                          item.route != '/about',
                    )
                    .toList()
                  ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton(
                key: const Key('healthFab'),
                tooltip: 'Manage Menu Items',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => BlocProvider.value(
                      value: context.read<MenuConfigBloc>(),
                      child: MenuItemListDialog(menuConfiguration: menuConfig),
                    ),
                  );
                },
                child: const Icon(Icons.menu),
              ),
              body: DashboardGrid(
                itemCount: dashboardItems.length,
                itemBuilder: (context, index) {
                  final item = dashboardItems[index];
                  return DashboardCard(
                    title: item.title,
                    iconName: item.iconName ?? 'dashboard',
                    route: item.route,
                    stats: getStatsForRoute(item.route, stats),
                    animationIndex: index,
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
