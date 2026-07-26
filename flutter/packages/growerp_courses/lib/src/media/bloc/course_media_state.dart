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
