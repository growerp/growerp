import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// Fetch events are throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

void main() {
  late MockRestClient restClient;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));
  setUp(() => restClient = MockRestClient());

  group('WebsiteTranslationBloc', () {
    final running = WebsiteTranslation(
      translationId: 'T1',
      ownerName: 'Acme',
      status: 'TRANSLATING',
    );
    final done = running.copyWith(status: 'COMPLETED');

    WebsiteTranslationBloc build() => WebsiteTranslationBloc(restClient);

    blocTest<WebsiteTranslationBloc, WebsiteTranslationState>(
      'WebsiteTranslationFetch_backgroundFinished_reportsAndUpdatesSelected',
      setUp: () =>
          when(
            () => restClient.getWebsiteTranslation(start: 0, limit: 20),
          ).thenAnswer(
            (_) async => WebsiteTranslations(websiteTranslations: [done]),
          ),
      build: build,
      seed: () => WebsiteTranslationState(
        status: WebsiteTranslationStatus.success,
        translations: [running],
        selected: running,
      ),
      act: (bloc) => bloc.add(const WebsiteTranslationFetch(background: true)),
      wait: fetchWait,
      expect: () => [
        isA<WebsiteTranslationState>()
            .having(
              (s) => s.status,
              'status',
              WebsiteTranslationStatus.pollSuccess,
            )
            .having((s) => s.message, 'message', 'Website of Acme translated')
            .having((s) => s.selected?.status, 'selected', 'COMPLETED'),
      ],
    );

    blocTest<WebsiteTranslationBloc, WebsiteTranslationState>(
      'WebsiteTranslationCreate_options_sendsYNFlagsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createWebsiteTranslation(
          ownerPartyId: 'O1',
          sourceLocale: 'en',
          targetLocales: 'th,nl',
          translateEntityNames: 'Y',
          overwriteExisting: 'N',
        ),
      ).thenAnswer((_) async => running),
      build: build,
      act: (bloc) => bloc.add(
        const WebsiteTranslationCreate(
          ownerPartyId: 'O1',
          targetLocales: 'th,nl',
          translateEntityNames: true,
        ),
      ),
      expect: () => [
        isA<WebsiteTranslationState>(),
        isA<WebsiteTranslationState>()
            .having((s) => s.status, 'status', WebsiteTranslationStatus.success)
            .having((s) => s.translations, 'translations', [running]),
      ],
    );

    blocTest<WebsiteTranslationBloc, WebsiteTranslationState>(
      'WebsiteTranslationCreate_noOwner_sendsNoOwnerPartyId',
      setUp: () => when(
        () => restClient.createWebsiteTranslation(
          sourceLocale: 'en',
          targetLocales: 'th',
          translateEntityNames: 'N',
          overwriteExisting: 'N',
        ),
      ).thenAnswer((_) async => running),
      build: build,
      act: (bloc) =>
          bloc.add(const WebsiteTranslationCreate(targetLocales: 'th')),
      expect: () => [
        isA<WebsiteTranslationState>(),
        isA<WebsiteTranslationState>()
            .having((s) => s.status, 'status', WebsiteTranslationStatus.success)
            .having((s) => s.translations, 'translations', [running]),
      ],
    );

    blocTest<WebsiteTranslationBloc, WebsiteTranslationState>(
      'WebsiteTranslationDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteWebsiteTranslation(translationId: 'T1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => WebsiteTranslationState(translations: [done]),
      act: (bloc) => bloc.add(WebsiteTranslationDelete(done)),
      expect: () => [
        isA<WebsiteTranslationState>(),
        isA<WebsiteTranslationState>().having(
          (s) => s.translations,
          'translations',
          isEmpty,
        ),
      ],
    );

    blocTest<WebsiteTranslationBloc, WebsiteTranslationState>(
      'WebsiteTranslationFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getWebsiteTranslation(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const WebsiteTranslationFetch()),
      wait: fetchWait,
      expect: () => [
        isA<WebsiteTranslationState>(),
        isA<WebsiteTranslationState>()
            .having((s) => s.status, 'status', WebsiteTranslationStatus.failure)
            .having((s) => s.message, 'message', 'No access'),
      ],
    );
  });
}
