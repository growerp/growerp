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

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

part 'course_media_event.dart';
part 'course_media_state.dart';

class CourseMediaBloc extends Bloc<CourseMediaEvent, CourseMediaState> {
  final RestClient restClient;

  CourseMediaBloc({required this.restClient})
      : super(const CourseMediaState()) {
    on<MediaFetch>(_onMediaFetch);
    on<MediaGenerate>(_onMediaGenerate);
    on<MediaUpdate>(_onMediaUpdate);
  }

  Future<void> _onMediaFetch(
    MediaFetch event,
    Emitter<CourseMediaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MediaBlocStatus.loading));

      final response = await restClient.listCourseMedia(
        courseId: event.courseId,
        platform: event.platform,
      );

      emit(
        state.copyWith(
          status: MediaBlocStatus.success,
          mediaList: response.mediaList,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: MediaBlocStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> _onMediaGenerate(
    MediaGenerate event,
    Emitter<CourseMediaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MediaBlocStatus.generating));

      final response = await restClient.generateCourseMedia(
        data: {
          'courseId': event.courseId,
          'platform': event.platform.name.toUpperCase(),
          if (event.moduleId != null) 'moduleId': event.moduleId,
          if (event.lessonId != null) 'lessonId': event.lessonId,
        },
      );

      final generatedMedia = CourseMedia(
        mediaId: response['mediaId'] as String?,
        generatedContent: response['generatedContent'] as String?,
        platform: event.platform,
        courseId: event.courseId,
      );

      emit(
        state.copyWith(
          status: MediaBlocStatus.success,
          generatedMedia: generatedMedia,
          mediaList: [generatedMedia, ...state.mediaList],
          message: 'Content generated successfully!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MediaBlocStatus.failure,
          message: 'Failed to generate content: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onMediaUpdate(
    MediaUpdate event,
    Emitter<CourseMediaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MediaBlocStatus.loading));

      await restClient.updateCourseMedia(data: event.media.toJson());

      final updatedList = state.mediaList.map((m) {
        return m.mediaId == event.media.mediaId ? event.media : m;
      }).toList();

      emit(
        state.copyWith(
          status: MediaBlocStatus.success,
          mediaList: updatedList,
          message: 'Media updated successfully',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: MediaBlocStatus.failure, message: e.toString()),
      );
    }
  }
}
