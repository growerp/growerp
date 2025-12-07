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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';

class AccountingForm extends StatelessWidget {
  const AccountingForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuConfigBloc, MenuConfigState>(
      builder: (context, state) {
        final menuConfig = state.menuConfiguration;
        if (menuConfig == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get dashboard items: accounting sub-options (FREELANCE_ACC_*)
        final dashboardOptions =
            menuConfig.menuOptions
                .where(
                  (option) =>
                      option.isActive &&
                      option.menuOptionId != null &&
                      option.menuOptionId!.startsWith('FREELANCE_ACC_'),
                )
                .toList()
              ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            key: const Key('accountingFab'),
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
                return _DashboardCard(
                  title: option.title,
                  iconName: option.iconName ?? 'dashboard',
                  route: option.route,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Dashboard card widget for displaying menu options
class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String? route;

  const _DashboardCard({
    required this.title,
    required this.iconName,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (route != null) {
            context.go(route!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getIconFromRegistry(iconName) ??
                  const Icon(Icons.dashboard, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
