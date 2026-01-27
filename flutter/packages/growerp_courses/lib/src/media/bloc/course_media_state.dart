/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

part of 'course_media_bloc.dart';

enum MediaBlocStatus { initial, loading, generating, success, failure }

class CourseMediaState extends Equatable {
  final MediaBlocStatus status;
  final List<CourseMedia> mediaList;
  final CourseMedia? generatedMedia;
  final String? message;

  const CourseMediaState({
    this.status = MediaBlocStatus.initial,
    this.mediaList = const [],
    this.generatedMedia,
    this.message,
  });

  CourseMediaState copyWith({
    MediaBlocStatus? status,
    List<CourseMedia>? mediaList,
    CourseMedia? generatedMedia,
    String? message,
  }) {
    return CourseMediaState(
      status: status ?? this.status,
      mediaList: mediaList ?? this.mediaList,
      generatedMedia: generatedMedia,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, mediaList, generatedMedia, message];
}
