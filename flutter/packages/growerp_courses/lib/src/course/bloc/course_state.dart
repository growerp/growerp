/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

part of 'course_bloc.dart';

enum CourseBlocStatus { initial, loading, success, failure }

class CourseState extends Equatable {
  final CourseBlocStatus status;
  final List<Course> courses;
  final Course? selectedCourse;
  final String? message;
  final bool hasReachedMax;

  const CourseState({
    this.status = CourseBlocStatus.initial,
    this.courses = const [],
    this.selectedCourse,
    this.message,
    this.hasReachedMax = false,
  });

  CourseState copyWith({
    CourseBlocStatus? status,
    List<Course>? courses,
    Course? selectedCourse,
    String? message,
    bool? hasReachedMax,
  }) {
    return CourseState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      selectedCourse: selectedCourse ?? this.selectedCourse,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
        status,
        courses,
        selectedCourse,
        message,
        hasReachedMax,
      ];

  @override
  String toString() =>
      'CourseState(status: $status, courses: ${courses.length})';
}
