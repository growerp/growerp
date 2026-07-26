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

import 'package:growerp_core/growerp_core.dart';
import 'course/views/course_list.dart';
import 'course/views/all_course_participants_view.dart';
import 'course/views/course_catalog_view.dart';
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
    'AllCourseParticipantsView': (args) => const AllCourseParticipantsView(),
    'CourseCatalogView': (args) => const CourseCatalogView(),
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
