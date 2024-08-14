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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: DashBoardForm(dashboardItems: [
            makeDashboardItem('dbRequests', context, menuOptions[1], [
              "Requests: ${authenticate.stats?.requests ?? 0}",
            ]),
            makeDashboardItem('dbCustomers', context, menuOptions[2], [
              "Customers: ${authenticate.stats?.customers ?? 0}",
            ]),
            makeDashboardItem('dbEmployees', context, menuOptions[3], [
              "Employees: ${authenticate.stats?.opportunities ?? 0}",
            ]),
            makeDashboardItem('dbCompany', context, menuOptions[4], [
              authenticate.company!.name!.length > 20
                  ? "${authenticate.company!.name!.substring(0, 20)}..."
                  : "${authenticate.company!.name}",
            ]),
          ]),
        ),
      ],
    );
  }
}
