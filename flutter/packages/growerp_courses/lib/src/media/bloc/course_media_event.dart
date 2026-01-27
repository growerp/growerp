/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
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
