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
