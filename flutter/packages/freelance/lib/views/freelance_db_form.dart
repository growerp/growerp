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

            // Get dashboard options from menu configuration (active items only)
            // Exclude the Main/Dashboard item itself (route '/'), About, and accounting routes
            final dashboardOptions =
                menuConfig.menuOptions
                    .where(
                      (option) =>
                          option.isActive &&
                          option.route != '/' &&
                          option.route != '/about' &&
                          option.route != '/accounting' &&
                          !(option.route?.startsWith('/accounting/') ?? false),
                    )
                    .toList()
                  ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton(
                key: const Key('freelanceFab'),
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
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
                    childAspectRatio: 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
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
              ),
            );
          },
        );
      },
    );
  }
}
