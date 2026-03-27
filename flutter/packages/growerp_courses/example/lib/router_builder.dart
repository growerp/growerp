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

import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
// Hide model class that conflicts with widget from courses package
import 'package:growerp_models/growerp_models.dart' hide CourseMediaList;
// Hide the model re-export from courses package
import 'package:growerp_courses/growerp_courses.dart' hide CourseMediaList;
// ignore: implementation_imports
import 'package:growerp_courses/src/media/views/course_media_list.dart'
    show CourseMediaList;
import 'views/courses_dashboard.dart';

/// Canonical menu configuration for Courses example app.
///
/// Used by both the production app (main.dart) and all integration tests.
const coursesMenuConfig = MenuConfiguration(
  menuConfigurationId: 'COURSES_EXAMPLE',
  appId: 'courses_example',
  name: 'Courses Example Menu',
  menuItems: [
    MenuItem(
      menuItemId: 'COURSES_MAIN',
      title: 'Main',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: 'CoursesDashboard',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'COURSES_LIST',
      title: 'Courses',
      route: '/courses',
      iconName: 'school',
      sequenceNum: 20,
      widgetName: 'CourseList',
      isActive: true,
    ),
    MenuItem(
      menuItemId: 'COURSES_MEDIA',
      title: 'Course Media',
      route: '/media',
      iconName: 'auto_awesome',
      sequenceNum: 30,
      widgetName: 'CourseMediaList',
      isActive: true,
    ),
  ],
);

/// Creates a static go_router for the courses example app.
///
/// Used by both the production app (main.dart) and all integration tests.
GoRouter createCoursesExampleRouter() {
  return createStaticAppRouter(
    menuConfig: coursesMenuConfig,
    appTitle: 'GrowERP Courses Example',
    dashboard: const CoursesDashboard(menuConfiguration: coursesMenuConfig),
    widgetBuilder: (route) => switch (route) {
      '/courses' => const CourseList(),
      '/media' => const CourseMediaList(courseId: null),
      _ => const CoursesDashboard(menuConfiguration: coursesMenuConfig),
    },
  );
}
