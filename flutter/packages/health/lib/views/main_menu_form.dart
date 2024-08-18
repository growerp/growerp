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

  bool access(UserGroup userGroup, MenuOption menuOption) {
    // print("===1=check for $userGroup in write: ${menuOption.writeGroups}");
    if (menuOption.writeGroups != null &&
        menuOption.writeGroups!.contains(userGroup)) return true;
    // print("==2==check for $userGroup in my: ${menuOption.myGroups}");
    if (menuOption.myGroups != null &&
        menuOption.myGroups!.contains(userGroup)) {
      return true;
    }
    // print("=3===check for $userGroup in read: ${menuOption.readGroups}");
    if (menuOption.readGroups != null &&
        menuOption.readGroups!.contains(userGroup)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    var userGroup =
        context.read<AuthBloc>().state.authenticate!.user!.userGroup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: DashBoardForm(dashboardItems: [
            if (access(userGroup!, menuOptions[1]))
              makeDashboardItem('dbRequests', context, menuOptions[1], [
                "#: ${authenticate.stats?.requests ?? 0}",
              ]),
            if (access(userGroup, menuOptions[2]))
              makeDashboardItem('dbCustomers', context, menuOptions[2], [
                "#: ${authenticate.stats?.customers ?? 0}",
              ]),
            if (access(userGroup, menuOptions[3]))
              makeDashboardItem('dbEmployees', context, menuOptions[3], [
                "#: ${authenticate.stats?.opportunities ?? 0}",
              ]),
            if (access(userGroup, menuOptions[4]))
              makeDashboardItem('dbCompany', context, menuOptions[4], [
                authenticate.company!.name!.length > 20
                    ? "${authenticate.company!.name!.substring(0, 20)}..."
                    : "${authenticate.company!.name}",
              ]),
            if (access(userGroup, menuOptions[5]))
              makeDashboardItem('dbCompany', context, menuOptions[5], []),
          ]),
        ),
      ],
    );
  }
}
