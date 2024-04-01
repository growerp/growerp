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

class WorkflowDbForm extends StatelessWidget {
  const WorkflowDbForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state.status == AuthStatus.authenticated) {
        Authenticate authenticate = state.authenticate!;
        return DashBoardForm(dashboardItems: [
          makeDashboardItem('dbWorkflows', context, menuOptions[1],
              ["Currently active workflows", "Workflows start here"]),
          makeDashboardItem('dbWorkflowTemplates', context, menuOptions[2],
              ["Workflow definitions"]),
          makeDashboardItem('dbWorkflowTemplateTasks', context, menuOptions[3],
              ["Workflow Task definitions"]),
          makeDashboardItem('dbToDos', context, menuOptions[4], [
            authenticate.company!.name!.length > 20
                ? "${authenticate.company!.name!.substring(0, 20)}..."
                : "${authenticate.company!.name}",
            "All open tasks: ${authenticate.stats?.allTasks ?? 0}",
            "Not Invoiced hours: ${authenticate.stats?.notInvoicedHours ?? 0}",
          ]),
        ]);
      }

      return const LoadingIndicator();
    });
  }
}
