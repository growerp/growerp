import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_courses/growerp_courses.dart' hide CourseMediaList;
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<CourseMediaState> mediaState(MediaBlocStatus status) =>
    isA<CourseMediaState>().having((s) => s.status, 'status', status);

void main() {
  late MockRestClient restClient;

  final post = CourseMedia(
    mediaId: 'MD1',
    courseId: 'C1',
    platform: MediaPlatform.linkedin,
    generatedContent: 'Learn Flutter',
  );

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));
  setUp(() => restClient = MockRestClient());

  CourseMediaBloc build() => CourseMediaBloc(restClient: restClient);

  blocTest<CourseMediaBloc, CourseMediaState>(
    'MediaFetch_courseAndPlatform_setsMediaList',
    setUp: () => when(
      () => restClient.listCourseMedia(courseId: 'C1', platform: 'LINKEDIN'),
    ).thenAnswer((_) async => CourseMediaList(mediaList: [post])),
    build: build,
    act: (bloc) =>
        bloc.add(const MediaFetch(courseId: 'C1', platform: 'LINKEDIN')),
    expect: () => [
      mediaState(MediaBlocStatus.loading),
      mediaState(
        MediaBlocStatus.success,
      ).having((s) => s.mediaList, 'mediaList', [post]),
    ],
  );

  blocTest<CourseMediaBloc, CourseMediaState>(
    'MediaFetch_restThrowsDio_emitsFailure',
    setUp: () => when(
      () => restClient.listCourseMedia(courseId: 'C1'),
    ).thenThrow(dioError('No access')),
    build: build,
    act: (bloc) => bloc.add(const MediaFetch(courseId: 'C1')),
    expect: () => [
      mediaState(MediaBlocStatus.loading),
      mediaState(MediaBlocStatus.failure),
    ],
  );

  blocTest<CourseMediaBloc, CourseMediaState>(
    'MediaUpdate_editedMedia_replacesItInList',
    setUp: () => when(
      () => restClient.updateCourseMedia(data: any(named: 'data')),
    ).thenAnswer((_) async => '{}'),
    build: build,
    seed: () => CourseMediaState(mediaList: [post]),
    act: (bloc) => bloc.add(
      MediaUpdate(
        CourseMedia(mediaId: 'MD1', courseId: 'C1', editedContent: 'Edited'),
      ),
    ),
    expect: () => [
      mediaState(MediaBlocStatus.loading),
      mediaState(MediaBlocStatus.success).having(
        (s) => s.mediaList.single.editedContent,
        'editedContent',
        'Edited',
      ),
    ],
  );

  blocTest<CourseMediaBloc, CourseMediaState>(
    'MediaGenerate_restThrowsDio_emitsFailure',
    setUp: () => when(
      () => restClient.generateCourseMedia(data: any(named: 'data')),
    ).thenThrow(dioError('AI unavailable')),
    build: build,
    act: (bloc) => bloc.add(
      const MediaGenerate(courseId: 'C1', platform: MediaPlatform.email),
    ),
    expect: () => [
      mediaState(MediaBlocStatus.generating),
      mediaState(MediaBlocStatus.failure),
    ],
  );

  group(
    'generated media body',
    skip: 'https://github.com/growerp/growerp/issues/44',
    () {
      // the Dio client uses ResponseType.plain: dynamic bodies are strings
      blocTest<CourseMediaBloc, CourseMediaState>(
        'MediaGenerate_jsonStringBody_addsGeneratedMedia',
        setUp: () =>
            when(
              () => restClient.generateCourseMedia(data: any(named: 'data')),
            ).thenAnswer(
              (_) async =>
                  jsonEncode({'mediaId': 'MD2', 'generatedContent': 'Hi all'}),
            ),
        build: build,
        act: (bloc) => bloc.add(
          const MediaGenerate(courseId: 'C1', platform: MediaPlatform.email),
        ),
        expect: () => [
          mediaState(MediaBlocStatus.generating),
          mediaState(
            MediaBlocStatus.success,
          ).having((s) => s.generatedMedia?.mediaId, 'mediaId', 'MD2'),
        ],
      );
    },
  );
}
