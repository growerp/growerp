/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

part 'course_event.dart';
part 'course_state.dart';

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
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onCourseGetDetail(
    CourseGetDetail event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      final response = await restClient.getCourse(
        courseId: event.courseId,
      );

      final course = Course.fromJson(
        response['course'] as Map<String, dynamic>,
      );

      emit(
        state.copyWith(
            status: CourseBlocStatus.success, selectedCourse: course),
      );
    } catch (e) {
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
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

      final newCourse = event.course.copyWith(
        courseId: response['courseId'] as String?,
        pseudoId: response['pseudoId'] as String?,
      );

      emit(
        state.copyWith(
          status: CourseBlocStatus.success,
          courses: [newCourse, ...state.courses],
          message: 'Course created successfully',
        ),
      );
    } catch (e) {
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
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
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onCourseDelete(
    CourseDelete event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.deleteCourse(
        courseId: event.course.courseId!,
      );

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
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
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
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onModuleUpdate(
    CourseModuleUpdate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.updateCourseModule(data: event.module.toJson());

      if (state.selectedCourse?.courseId != null) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onModuleDelete(
    CourseModuleDelete event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.deleteCourseModule(
        moduleId: event.module.moduleId!,
      );

      if (state.selectedCourse?.courseId != null) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
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

      if (state.selectedCourse?.courseId != null) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLessonUpdate(
    CourseLessonUpdate event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.updateCourseLesson(data: event.lesson.toJson());

      if (state.selectedCourse?.courseId != null) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLessonDelete(
    CourseLessonDelete event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseBlocStatus.loading));

      await restClient.deleteCourseLesson(
        lessonId: event.lesson.lessonId!,
      );

      if (state.selectedCourse?.courseId != null) {
        add(CourseGetDetail(state.selectedCourse!.courseId!));
      }
    } catch (e) {
      emit(state.copyWith(
          status: CourseBlocStatus.failure, message: e.toString()));
    }
  }
}
