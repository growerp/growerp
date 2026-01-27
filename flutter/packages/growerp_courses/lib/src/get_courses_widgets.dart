/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:growerp_core/growerp_core.dart';
import 'course/views/course_list.dart';
import 'media/views/course_media_list.dart';
import 'viewer/views/course_viewer.dart';

/// Returns widget mappings for the courses package
Map<String, GrowerpWidgetBuilder> getCoursesWidgets() {
  return {
    'CourseList': (args) => const CourseList(),
    'CourseViewer': (args) =>
        CourseViewer(courseId: args?['courseId'] as String? ?? ''),
    'CourseMediaList': (args) =>
        CourseMediaList(courseId: args?['courseId'] as String?),
  };
}

/// Returns widget metadata with icons for the courses package
List<WidgetMetadata> getCoursesWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'CourseList',
      description: 'List of courses with modules and lessons',
      iconName: 'school',
      keywords: ['course', 'training', 'learning', 'education'],
      builder: (args) => const CourseList(),
    ),
    WidgetMetadata(
      widgetName: 'CourseViewer',
      description: 'In-app course viewer with progress tracking',
      iconName: 'play_circle_outline',
      keywords: ['viewer', 'player', 'lesson', 'progress'],
      builder: (args) =>
          CourseViewer(courseId: args?['courseId'] as String? ?? ''),
    ),
    WidgetMetadata(
      widgetName: 'CourseMediaList',
      description: 'AI-generated course content for various platforms',
      iconName: 'auto_awesome',
      keywords: ['media', 'ai', 'content', 'generation'],
      builder: (args) =>
          CourseMediaList(courseId: args?['courseId'] as String?),
    ),
  ];
}
