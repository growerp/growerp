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
import '../menu_options.dart';

class AdminDbForm extends StatelessWidget {
  const AdminDbForm({super.key});

  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    final localizations = CoreLocalizations.of(context)!;
    List<Widget> dashboardItems = [];

    for (final option in getMenuOptions(context, localizations)) {
      if (option.userGroups!.contains(authenticate.user?.userGroup!) &&
          option.title != localizations.main) {
        dashboardItems.add(
          makeDashboardItem(option.key ?? '', context, option, [
            if (option.key == 'dbRequests')
              "#: ${authenticate.stats?.requests ?? 0}",
            if (option.key == 'dbCustomers')
              "#: ${authenticate.stats?.customers}",
            if (option.key == 'dbEmployees')
              "#: ${authenticate.stats?.employees ?? 0}",
          ]),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: DashBoardForm(dashboardItems: dashboardItems)),
      ],
    );
  }
}
