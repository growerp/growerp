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

part of 'course_media_bloc.dart';

abstract class CourseMediaEvent extends Equatable {
  const CourseMediaEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch media for a course
class MediaFetch extends CourseMediaEvent {
  final String? courseId;
  final String? platform;

  const MediaFetch({this.courseId, this.platform});

  @override
  List<Object?> get props => [courseId, platform];
}

/// Generate media using AI
class MediaGenerate extends CourseMediaEvent {
  final String courseId;
  final MediaPlatform platform;
  final String? moduleId;
  final String? lessonId;

  const MediaGenerate({
    required this.courseId,
    required this.platform,
    this.moduleId,
    this.lessonId,
  });

  @override
  List<Object?> get props => [courseId, platform, moduleId, lessonId];
}

/// Update media content
class MediaUpdate extends CourseMediaEvent {
  final CourseMedia media;

  const MediaUpdate(this.media);

  @override
  List<Object?> get props => [media];
}
