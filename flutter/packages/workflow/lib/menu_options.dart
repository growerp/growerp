/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_task/growerp_task.dart';
import 'views/workflow_db_form.dart' as local;
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: 'packages/growerp_core/images/dashBoardGrey.png',
    selectedImage: 'packages/growerp_core/images/dashBoard.png',
    title: 'Main',
    route: '/',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const local.WorkflowDbForm(),
  ),
  MenuOption(
    image: "packages/growerp_core/images/workflow.png",
    selectedImage: "packages/growerp_core/images/workflow.png",
    title: "Workflows",
    route: '/workflows',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin, UserGroup.employee],
    child: const TaskList(TaskType.workflow),
  ),
  MenuOption(
    image: "packages/growerp_core/images/workflow.png",
    selectedImage: "packages/growerp_core/images/workflow.png",
    title: "Workflow Templates",
    route: '/workflowTemplates',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin, UserGroup.employee],
    child: const TaskList(TaskType.workflowTemplate),
  ),
/*  MenuOption(
    image: "packages/growerp_core/images/workflow.png",
    selectedImage: "packages/growerp_core/images/workflow.png",
    title: "Workflow Task Templates",
    route: '/workflowTaskTemplates',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin, UserGroup.employee],
    child: const TaskList(TaskType.workflowTaskTemplate),
  ),
*/
  MenuOption(
    image: "packages/growerp_core/images/tasksGrey.png",
    selectedImage: "packages/growerp_core/images/tasks.png",
    title: "ToDo List",
    route: '/toDo',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin, UserGroup.employee],
    child: const TaskList(TaskType.todo),
  ),
];
