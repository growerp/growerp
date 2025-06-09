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
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> menuOptions = [
  MenuOption(
    image: "packages/growerp_core/images/activitiesGrey.png",
    selectedImage: "packages/growerp_core/images/activities.png",
    title: "ToDo List",
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const ActivityList(ActivityType.todo),
  ),
];
