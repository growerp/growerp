/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

part of 'course_viewer_bloc.dart';

abstract class CourseViewerEvent extends Equatable {
  const CourseViewerEvent();

  @override
  List<Object?> get props => [];
}

/// Load a course for viewing
class LoadCourse extends CourseViewerEvent {
  final String courseId;

  const LoadCourse(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

/// Select a specific lesson
class SelectLesson extends CourseViewerEvent {
  final CourseLesson lesson;

  const SelectLesson(this.lesson);

  @override
  List<Object?> get props => [lesson];
}

/// Mark a lesson as complete
class MarkLessonComplete extends CourseViewerEvent {
  final String lessonId;

  const MarkLessonComplete(this.lessonId);

  @override
  List<Object?> get props => [lessonId];
}

/// Navigate to next lesson
class NextLesson extends CourseViewerEvent {
  const NextLesson();
}

/// Navigate to previous lesson
class PreviousLesson extends CourseViewerEvent {
  const PreviousLesson();
}

/// Fetch available courses for selection
class FetchAvailableCourses extends CourseViewerEvent {
  const FetchAvailableCourses();
}

/// Fetch media for the current course
class FetchCourseMedia extends CourseViewerEvent {
  const FetchCourseMedia();
}

/// Select a media item to view
class SelectMedia extends CourseViewerEvent {
  final CourseMedia? media;

  const SelectMedia(this.media);

  @override
  List<Object?> get props => [media];
}
