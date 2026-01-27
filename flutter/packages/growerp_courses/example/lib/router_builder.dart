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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
// Hide model class that conflicts with widget from courses package
import 'package:growerp_models/growerp_models.dart' hide CourseMediaList;
import 'package:growerp_user_company/growerp_user_company.dart';
// Hide the model re-export from courses package
import 'package:growerp_courses/growerp_courses.dart' hide CourseMediaList;
// ignore: implementation_imports
import 'package:growerp_courses/src/media/views/course_media_list.dart'
    show CourseMediaList;
import 'views/courses_dashboard.dart';

/// Create the dynamic router for Courses example app
///
/// This is used by integration tests to create a router with test configurations.
GoRouter createDynamicCoursesRouter(
  List<MenuConfiguration> configurations, {
  GlobalKey<NavigatorState>? rootNavigatorKey,
}) {
  // Register widgets before creating router
  for (final widgets in coursesWidgetRegistrations) {
    WidgetRegistry.register(widgets);
  }

  return createDynamicAppRouter(
    configurations,
    rootNavigatorKey: rootNavigatorKey,
    config: const DynamicRouterConfig(
      widgetLoader: WidgetRegistry.getWidget,
      appTitle: 'Courses Example',
    ),
  );
}

/// Widget registrations for Courses example app
List<Map<String, GrowerpWidgetBuilder>> coursesWidgetRegistrations = [
  getUserCompanyWidgets(),
  // Add courses widgets with correct nullability
  {
    'CourseList': (args) => const CourseList(),
    'CourseMediaList': (args) =>
        CourseMediaList(courseId: args?['courseId'] as String?),
    'CourseViewer': (args) =>
        CourseViewer(courseId: args?['courseId'] as String? ?? ''),
  },
  // App-specific widgets
  {
    'CoursesDashboard': (args) => const CoursesDashboard(),
    'AboutForm': (args) => const AboutForm(),
    'SystemSetupDialog': (args) => const SystemSetupDialog(),
  },
];
