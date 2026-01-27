/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

part of 'course_bloc.dart';

abstract class CourseEvent extends Equatable {
  const CourseEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch list of courses
class CourseFetch extends CourseEvent {
  final String? searchString;
  final bool refresh;
  final int limit;

  const CourseFetch({this.searchString, this.refresh = false, this.limit = 20});

  @override
  List<Object?> get props => [searchString, refresh, limit];
}

/// Get single course with details
class CourseGetDetail extends CourseEvent {
  final String courseId;

  const CourseGetDetail(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

/// Create new course
class CourseCreate extends CourseEvent {
  final Course course;

  const CourseCreate(this.course);

  @override
  List<Object?> get props => [course];
}

/// Update existing course
class CourseUpdate extends CourseEvent {
  final Course course;

  const CourseUpdate(this.course);

  @override
  List<Object?> get props => [course];
}

/// Delete course
class CourseDelete extends CourseEvent {
  final Course course;

  const CourseDelete(this.course);

  @override
  List<Object?> get props => [course];
}

/// Create module in course
class CourseModuleCreate extends CourseEvent {
  final String courseId;
  final CourseModule module;

  const CourseModuleCreate({required this.courseId, required this.module});

  @override
  List<Object?> get props => [courseId, module];
}

/// Update module
class CourseModuleUpdate extends CourseEvent {
  final CourseModule module;

  const CourseModuleUpdate(this.module);

  @override
  List<Object?> get props => [module];
}

/// Delete module
class CourseModuleDelete extends CourseEvent {
  final CourseModule module;

  const CourseModuleDelete(this.module);

  @override
  List<Object?> get props => [module];
}

/// Create lesson in module
class CourseLessonCreate extends CourseEvent {
  final String moduleId;
  final CourseLesson lesson;

  const CourseLessonCreate({required this.moduleId, required this.lesson});

  @override
  List<Object?> get props => [moduleId, lesson];
}

/// Update lesson
class CourseLessonUpdate extends CourseEvent {
  final CourseLesson lesson;

  const CourseLessonUpdate(this.lesson);

  @override
  List<Object?> get props => [lesson];
}

/// Delete lesson
class CourseLessonDelete extends CourseEvent {
  final CourseLesson lesson;

  const CourseLessonDelete(this.lesson);

  @override
  List<Object?> get props => [lesson];
}
