/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

part of 'course_viewer_bloc.dart';

enum ViewerStatus { initial, loading, selectingCourse, success, failure }

class CourseViewerState extends Equatable {
  final ViewerStatus status;
  final Course? course;
  final CourseLesson? currentLesson;
  final CourseProgress? progress;
  final String? message;
  final List<Course> availableCourses;
  final List<CourseMedia> mediaList;
  final CourseMedia? selectedMedia;

  const CourseViewerState({
    this.status = ViewerStatus.initial,
    this.course,
    this.currentLesson,
    this.progress,
    this.message,
    this.availableCourses = const [],
    this.mediaList = const [],
    this.selectedMedia,
  });

  CourseViewerState copyWith({
    ViewerStatus? status,
    Course? course,
    CourseLesson? currentLesson,
    CourseProgress? progress,
    String? message,
    List<Course>? availableCourses,
    List<CourseMedia>? mediaList,
    CourseMedia? selectedMedia,
  }) {
    return CourseViewerState(
      status: status ?? this.status,
      course: course ?? this.course,
      currentLesson: currentLesson ?? this.currentLesson,
      progress: progress ?? this.progress,
      message: message,
      availableCourses: availableCourses ?? this.availableCourses,
      mediaList: mediaList ?? this.mediaList,
      selectedMedia: selectedMedia,
    );
  }

  @override
  List<Object?> get props =>
      [status, course, currentLesson, progress, message, availableCourses, mediaList, selectedMedia];
}
