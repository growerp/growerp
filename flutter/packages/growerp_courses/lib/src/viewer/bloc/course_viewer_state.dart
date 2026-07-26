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
