/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'course_event.dart';
part 'course_state.dart';

const _courseSearchDebounceDuration = Duration(milliseconds: 300);
EventTransformer<CourseSearchChanged> courseSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_courseSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final RestClient restClient;

  CourseBloc({required this.restClient}) : super(const CourseState()) {
    on<CourseFetch>(_onCourseFetch);
    on<CourseGetDetail>(_onCourseGetDetail);
    on<CourseCreate>(_onCourseCreate);
    on<CourseUpdate>(_onCourseUpdate);
    on<CourseDelete>(_onCourseDelete);
    on<CourseModuleCreate>(_onModuleCreate);
    on<CourseModuleUpdate>(_onModuleUpdate);
    on<CourseModuleDelete>(_onModuleDelete);
    on<CourseLessonCreate>(_onLessonCreate);
    on<CourseLessonUpdate>(_onLessonUpdate);
    on<CourseLessonDelete>(_onLessonDelete);
    on<CourseSubscribe>(_onCourseSubscribe);
    on<CourseMediaGenerate>(_onMediaGenerate);
    on<CourseParticipantsFetch>(_onParticipantsFetch);
    on<CourseAllParticipantsFetch>(_onAllParticipantsFetch);
    on<CourseSearchChanged>(
      _onCourseSearchChanged,
      transformer: courseSearchDebounce(),
    );
  }

  /// Helper to check if selectedCourse has a valid (non-null, non-empty) courseId
  bool get _hasValidSelectedCourseId {
    final courseId = state.selectedCourse?.courseId;
    return courseId != null && courseId.isNotEmpty;
  }

  Future<void> _onCourseSearchChanged(
    CourseSearchChanged event,
    Emitter<CourseState> emit,
  ) async {
    return _onCourseFetch(
      CourseFetch(
        refresh: event.refresh,
        searchString: event.searchString,
        limit: event.limit,
      ),
      emit,
    );
  }

  Future<void> _onCourseFetch(
    CourseFetch event,
    Emitter<CourseState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;

    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      final response = await restClient.listCourses(
        filter: event.searchString,
        limit: event.limit,
        start: event.refresh ? 0 : state.courses.length,
      );

      final courses = response.courses;

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          courses: event.refresh ? courses : [...state.courses, ...courses],
          hasReachedMax: courses.length < event.limit,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onCourseGetDetail(
    CourseGetDetail event,
    Emitter<CourseState> emit,
  ) async {
    // Guard against empty courseId
    if (event.courseId.isEmpty) {
      emit(
        state.copyWith(
          status: CourseBlocStatus.failure,
          message: 'Course ID is required',
        ),
      );
      return;
    }

    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      final response = await restClient.getCourse(courseId: event.courseId);
      final decoded = json.decode(response as String) as Map<String, dynamic>;

      final course = Course.fromJson(decoded['course'] as Map<String, dynamic>);

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          selectedCourse: course,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onCourseCreate(
    CourseCreate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      final response = await restClient.createCourse(
        data: event.course.toJson(),
      );
      final decoded = json.decode(response as String) as Map<String, dynamic>;

      final newCourse = event.course.copyWith(
        courseId: decoded['courseId'] as String?,
        pseudoId: decoded['pseudoId'] as String?,
        productId: decoded['productId'] as String?,
      );

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          courses: [newCourse, ...state.courses],
          message: 'Course created successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onCourseUpdate(
    CourseUpdate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.updateCourse(data: event.course.toJson());

      final updatedCourses = state.courses.map((c) {
        return c.courseId == event.course.courseId ? event.course : c;
      }).toList();

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          courses: updatedCourses,
          selectedCourse: event.course,
          message: 'Course updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onCourseDelete(
    CourseDelete event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.deleteCourse(courseId: event.course.courseId!);

      final updatedCourses = state.courses
          .where((c) => c.courseId != event.course.courseId)
          .toList();

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          courses: updatedCourses,
          message: 'Course deleted successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onModuleCreate(
    CourseModuleCreate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.createCourseModule(
        data: {'courseId': event.courseId, ...event.module.toJson()},
      );

      // Refresh the course detail
      add(CourseGetDetail(event.courseId));
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onModuleUpdate(
    CourseModuleUpdate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.updateCourseModule(data: event.module.toJson());

      if (_hasValidSelectedCourseId) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onModuleDelete(
    CourseModuleDelete event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.deleteCourseModule(moduleId: event.module.moduleId!);

      if (_hasValidSelectedCourseId) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onLessonCreate(
    CourseLessonCreate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.createCourseLesson(
        data: {'moduleId': event.moduleId, ...event.lesson.toJson()},
      );

      if (_hasValidSelectedCourseId) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onLessonUpdate(
    CourseLessonUpdate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.updateCourseLesson(data: event.lesson.toJson());

      if (_hasValidSelectedCourseId) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onLessonDelete(
    CourseLessonDelete event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.deleteCourseLesson(lessonId: event.lesson.lessonId!);

      if (_hasValidSelectedCourseId) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onParticipantsFetch(
    CourseParticipantsFetch event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      final response = await restClient.getCourseParticipants(
        courseId: event.courseId,
      );

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          participants: response.participants,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onAllParticipantsFetch(
    CourseAllParticipantsFetch event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      final response = await restClient.getAllCourseParticipants(
        filter: event.searchString,
        start: event.refresh ? 0 : state.allParticipants.length,
        limit: 50,
      );

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          allParticipants: event.refresh
              ? response.participants
              : [...state.allParticipants, ...response.participants],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onCourseSubscribe(
    CourseSubscribe event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.subscribeCourse(
        data: {
          'courseId': event.courseId,
          if (event.creditCardNumber != null)
            'creditCardNumber': event.creditCardNumber,
          if (event.nameOnCard != null) 'nameOnCard': event.nameOnCard,
          if (event.expireMonth != null) 'expireMonth': event.expireMonth,
          if (event.expireYear != null) 'expireYear': event.expireYear,
          if (event.cVC != null) 'cVC': event.cVC,
        },
      );

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          message: 'Successfully subscribed to course',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onMediaGenerate(
    CourseMediaGenerate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.generateCourseMedia(
        data: {
          'courseId': event.courseId,
          'platform': event.platform.name.toUpperCase(),
          'mediaType': event.mediaType.name.toUpperCase(),
          if (event.moduleId != null) 'moduleId': event.moduleId,
          if (event.lessonId != null) 'lessonId': event.lessonId,
        },
      );

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          message:
              'Media content generated successfully for ${event.platform.name}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CourseBlocStatus.failure, message: e.toString()),
      );
    }
  }
}
