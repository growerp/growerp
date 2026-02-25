/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    on<FetchAvailableCourses>(_onFetchAvailableCourses);
    on<FetchCourseMedia>(_onFetchCourseMedia);
    on<SelectMedia>(_onSelectMedia);
  }

  Future<void> _onLoadCourse(
    LoadCourse event,
    Emitter<CourseViewerState> emit,
  ) async {
    // If courseId is empty, fetch available courses instead
    if (event.courseId.isEmpty) {
      add(const FetchAvailableCourses());
      return;
    }

    try {
      emit(state.copyWith(status: ViewerStatus.loading));

      // Get course details
      dynamic courseResponse = await restClient.getCourse(
        courseId: event.courseId,
      );
      if (courseResponse is String) {
        courseResponse = jsonDecode(courseResponse);
      }
      final course = Course.fromJson(
        courseResponse['course'] as Map<String, dynamic>,
      );

      // Get user progress
      dynamic progressResponse = await restClient.getCourseProgress(
        courseId: event.courseId,
      );
      if (progressResponse is String) {
        progressResponse = jsonDecode(progressResponse);
      }
      final progress = CourseProgress.fromJson(
        progressResponse['progress'] as Map<String, dynamic>,
      );

      // Get course media
      List<CourseMedia> mediaList = [];
      try {
        final mediaResponse = await restClient.listCourseMedia(
          courseId: event.courseId,
        );
        mediaList = mediaResponse.mediaList;
      } catch (_) {
        // Media is optional, continue without it
      }

      // Select the first not-yet-completed lesson; fall back to the first lesson
      CourseLesson? firstLesson;
      if (course.modules != null) {
        final completed = progress.completedLessons ?? [];
        outer:
        for (final module in course.modules!) {
          for (final lesson in module.lessons ?? []) {
            if (lesson.lessonId != null &&
                !completed.contains(lesson.lessonId)) {
              firstLesson = lesson;
              break outer;
            }
          }
        }
        // All lessons completed (or no progress yet) – open the first lesson
        firstLesson ??= course.modules!.isNotEmpty &&
                (course.modules!.first.lessons?.isNotEmpty ?? false)
            ? course.modules!.first.lessons!.first
            : null;
      }

      emit(
        state.copyWith(
          status: ViewerStatus.success,
          course: course,
          currentLesson: firstLesson,
          progress: progress,
          mediaList: mediaList,
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
      dynamic response = await restClient.updateCourseProgress(
        data: {
          'courseId': state.course!.courseId,
          'lessonId': event.lessonId,
          'completed': true,
        },
      );

      // Decode response if it's a String
      if (response is String) {
        response = jsonDecode(response);
      }

      // Handle progressPercent being returned as int or String
      final progressValue = response['progressPercent'];
      final progressPercent = progressValue is int
          ? progressValue
          : int.tryParse(progressValue?.toString() ?? '0') ?? 0;

      final newProgress = (state.progress ?? CourseProgress()).copyWith(
        progressPercent: progressPercent,
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

  Future<void> _onFetchAvailableCourses(
    FetchAvailableCourses event,
    Emitter<CourseViewerState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ViewerStatus.loading));

      final response = await restClient.listCourses(
        limit: 50,
        start: 0,
      );

      emit(state.copyWith(
        status: ViewerStatus.selectingCourse,
        availableCourses: response.courses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ViewerStatus.failure,
        message: 'Failed to load courses: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchCourseMedia(
    FetchCourseMedia event,
    Emitter<CourseViewerState> emit,
  ) async {
    if (state.course?.courseId == null) return;

    try {
      dynamic response = await restClient.listCourseMedia(
        courseId: state.course!.courseId!,
      );

      if (response is String) {
        response = jsonDecode(response);
      }

      final mediaListJson = response['mediaList'] as List<dynamic>? ?? [];
      final mediaList = mediaListJson
          .map((json) => CourseMedia.fromJson(json as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(mediaList: mediaList));
    } catch (e) {
      // Silently fail - media is optional
      emit(state.copyWith(mediaList: []));
    }
  }

  Future<void> _onSelectMedia(
    SelectMedia event,
    Emitter<CourseViewerState> emit,
  ) async {
    emit(state.copyWith(selectedMedia: event.media));
  }
}
