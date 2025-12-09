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

/// Accounting dashboard for the Freelance app.
/// Uses the shared AccountingDashboard with FREELANCE_ACC_ prefix
/// and includes a FAB for menu management.
class AccountingForm extends StatelessWidget {
  const AccountingForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuConfigBloc, MenuConfigState>(
      builder: (context, state) {
        final menuConfig = state.menuConfiguration;

        return AccountingDashboard(
          menuOptionPrefix: 'FREELANCE_ACC_',
          floatingActionButton: menuConfig != null
              ? FloatingActionButton(
                  key: const Key('accountingFab'),
                  tooltip: 'Manage Menu Items',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                        value: context.read<MenuConfigBloc>(),
                        child: MenuItemListDialog(
                          menuConfiguration: menuConfig,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.menu),
                )
              : null,
        );
      },
    );
  }
}
