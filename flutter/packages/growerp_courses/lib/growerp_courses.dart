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

// Models - exported from growerp_models
export 'package:growerp_courses/l10n/generated/courses_localizations.dart';
export 'package:growerp_models/growerp_models.dart'
    show
        Course,
        Courses,
        CourseModule,
        CourseModules,
        CourseLesson,
        CourseLessons,
        CourseMedia,
        // CourseMediaList is hidden to avoid collision with view
        CourseProgress,
        CourseParticipant,
        CourseParticipants,
        MediaPlatform,
        MediaType,
        CourseDifficulty;

// BLoC exports
export 'src/course/bloc/course_bloc.dart';
export 'src/media/bloc/course_media_bloc.dart';
export 'src/viewer/bloc/course_viewer_bloc.dart';

// Views exports
export 'src/course/views/course_list.dart';
export 'src/course/views/course_dialog.dart';
export 'src/course/views/course_detail.dart';
export 'src/course/views/course_participants_view.dart';
export 'src/course/views/all_course_participants_view.dart';
export 'src/course/views/course_catalog_view.dart';
export 'src/course/views/course_payment_dialog.dart';

export 'src/media/views/course_media_list.dart';
export 'src/media/views/generate_media_dialog.dart';
export 'src/media/views/media_preview.dart';

export 'src/viewer/views/course_viewer.dart';
export 'src/viewer/views/lesson_player.dart';
export 'src/viewer/views/course_progress_bar.dart';
export 'src/viewer/views/help_overlay.dart';

// Provider and widget registration
export 'src/get_courses_bloc_providers.dart';
export 'src/get_courses_widgets.dart';
