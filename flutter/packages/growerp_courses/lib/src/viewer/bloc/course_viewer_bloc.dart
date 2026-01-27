/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

part 'course_viewer_event.dart';
part 'course_viewer_state.dart';

class CourseViewerBloc extends Bloc<CourseViewerEvent, CourseViewerState> {
  final RestClient restClient;

  CourseViewerBloc({required this.restClient})
      : super(const CourseViewerState()) {
    on<LoadCourse>(_onLoadCourse);
    on<SelectLesson>(_onSelectLesson);
    on<MarkLessonComplete>(_onMarkLessonComplete);
    on<NextLesson>(_onNextLesson);
    on<PreviousLesson>(_onPreviousLesson);
  }

  Future<void> _onLoadCourse(
    LoadCourse event,
    Emitter<CourseViewerState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ViewerStatus.loading));

      // Get course details
      final courseResponse = await restClient.getCourse(
        courseId: event.courseId,
      );
      final course = Course.fromJson(
        courseResponse['course'] as Map<String, dynamic>,
      );

      // Get user progress
      final progressResponse = await restClient.getCourseProgress(
        courseId: event.courseId,
      );
      final progress = CourseProgress.fromJson(
        progressResponse['progress'] as Map<String, dynamic>,
      );

      // Set first lesson as current if none selected
      CourseLesson? firstLesson;
      if (course.modules != null && course.modules!.isNotEmpty) {
        final firstModule = course.modules!.first;
        if (firstModule.lessons != null && firstModule.lessons!.isNotEmpty) {
          firstLesson = firstModule.lessons!.first;
        }
      }

      emit(
        state.copyWith(
          status: ViewerStatus.success,
          course: course,
          currentLesson: firstLesson,
          progress: progress,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ViewerStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onSelectLesson(
    SelectLesson event,
    Emitter<CourseViewerState> emit,
  ) async {
    emit(state.copyWith(currentLesson: event.lesson));
  }

  Future<void> _onMarkLessonComplete(
    MarkLessonComplete event,
    Emitter<CourseViewerState> emit,
  ) async {
    if (state.course?.courseId == null) return;

    try {
      final response = await restClient.updateCourseProgress(
        data: {
          'courseId': state.course!.courseId,
          'lessonId': event.lessonId,
          'completed': true,
        },
      );

      final newProgress = (state.progress ?? CourseProgress()).copyWith(
        progressPercent: response['progressPercent'] as int?,
        completedLessons: [
          ...?state.progress?.completedLessons,
          event.lessonId,
        ],
      );

      emit(state.copyWith(progress: newProgress));
    } catch (e) {
      emit(
        state.copyWith(
          status: ViewerStatus.failure,
          message: 'Failed to update progress: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onNextLesson(
    NextLesson event,
    Emitter<CourseViewerState> emit,
  ) async {
    final allLessons = _getAllLessons();
    final currentIndex = allLessons.indexWhere(
      (l) => l.lessonId == state.currentLesson?.lessonId,
    );

    if (currentIndex >= 0 && currentIndex < allLessons.length - 1) {
      emit(state.copyWith(currentLesson: allLessons[currentIndex + 1]));
    }
  }

  Future<void> _onPreviousLesson(
    PreviousLesson event,
    Emitter<CourseViewerState> emit,
  ) async {
    final allLessons = _getAllLessons();
    final currentIndex = allLessons.indexWhere(
      (l) => l.lessonId == state.currentLesson?.lessonId,
    );

    if (currentIndex > 0) {
      emit(state.copyWith(currentLesson: allLessons[currentIndex - 1]));
    }
  }

  List<CourseLesson> _getAllLessons() {
    if (state.course == null) return [];
    final lessons = <CourseLesson>[];
    for (final module in state.course!.modules ?? []) {
      lessons.addAll(module.lessons ?? []);
    }
    return lessons;
  }
}
