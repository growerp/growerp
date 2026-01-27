/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

library growerp_courses;

// Models - exported from growerp_models
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
