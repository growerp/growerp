/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
