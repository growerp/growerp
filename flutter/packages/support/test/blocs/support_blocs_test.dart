import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:support/src/application/blocs/application_bloc.dart';
import 'package:support/src/gl_account_translation/blocs/gl_account_translation_bloc.dart';

import '../shared/mocks.dart';

// Fetch events are throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

void main() {
  late MockRestClient restClient;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));
  setUp(() => restClient = MockRestClient());

  group('ApplicationBloc', () {
    final admin = Application(applicationId: 'AppAdmin', version: '1.21.0');
    final hotel = Application(applicationId: 'AppHotel', version: '1.20.3');

    TypeMatcher<ApplicationState> appState(
      ApplicationStatus status, {
      List<Application>? apps,
      String? message,
    }) {
      var m = isA<ApplicationState>().having((s) => s.status, 'status', status);
      if (apps != null) m = m.having((s) => s.applications, 'apps', apps);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    ApplicationBloc build() => ApplicationBloc(restClient);

    blocTest<ApplicationBloc, ApplicationState>(
      'ApplicationFetch_initial_listsApplications',
      setUp: () => when(
        () => restClient.getApplication(),
      ).thenAnswer((_) async => Applications(applications: [admin, hotel])),
      build: build,
      act: (bloc) => bloc.add(const ApplicationFetch()),
      wait: fetchWait,
      expect: () => [
        appState(ApplicationStatus.success, apps: [admin, hotel]),
      ],
    );

    blocTest<ApplicationBloc, ApplicationState>(
      'ApplicationFetch_restThrowsDio_emitsFailure',
      setUp: () =>
          when(() => restClient.getApplication()).thenThrow(dioError('Nope')),
      build: build,
      act: (bloc) => bloc.add(const ApplicationFetch()),
      wait: fetchWait,
      expect: () => [appState(ApplicationStatus.failure, message: 'Nope')],
    );

    blocTest<ApplicationBloc, ApplicationState>(
      'ApplicationUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () => restClient.createApplication(hotel.copyWith(version: '1.21.0')),
      ).thenAnswer((_) async => hotel.copyWith(version: '1.21.0')),
      build: build,
      seed: () => ApplicationState(applications: [admin, hotel]),
      act: (bloc) =>
          bloc.add(ApplicationUpdate(hotel.copyWith(version: '1.21.0'))),
      expect: () => [
        appState(ApplicationStatus.loading),
        appState(
          ApplicationStatus.success,
          apps: [
            admin,
            hotel.copyWith(version: '1.21.0'),
          ],
          message: 'Application AppHotel updated!',
        ),
      ],
    );

    blocTest<ApplicationBloc, ApplicationState>(
      'ApplicationUpdate_new_insertsFirst',
      setUp: () => when(
        () => restClient.createApplication(Application(version: '1.0.0')),
      ).thenAnswer((_) async => hotel),
      build: build,
      seed: () => ApplicationState(applications: [admin]),
      act: (bloc) => bloc.add(ApplicationUpdate(Application(version: '1.0.0'))),
      expect: () => [
        appState(ApplicationStatus.loading),
        appState(ApplicationStatus.success, apps: [hotel, admin]),
      ],
    );

    blocTest<ApplicationBloc, ApplicationState>(
      'ApplicationDelete_existing_keepsRowButClearsContent',
      setUp: () => when(
        () => restClient.deleteApplication(hotel),
      ).thenAnswer((_) async => hotel),
      build: build,
      seed: () => ApplicationState(applications: [admin, hotel]),
      act: (bloc) => bloc.add(ApplicationDelete(hotel)),
      expect: () => [
        appState(ApplicationStatus.loading),
        appState(
          ApplicationStatus.success,
          apps: [
            admin,
            Application(applicationId: 'AppHotel'),
          ],
        ),
      ],
    );

    blocTest<ApplicationBloc, ApplicationState>(
      'ApplicationDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteApplication(hotel),
      ).thenThrow(dioError('Not allowed')),
      build: build,
      seed: () => ApplicationState(applications: [hotel]),
      act: (bloc) => bloc.add(ApplicationDelete(hotel)),
      expect: () => [
        appState(ApplicationStatus.loading),
        appState(ApplicationStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  group('GlAccountTranslationBloc', () {
    final thaiDone = GlAccountTranslation(
      locale: 'th',
      language: 'Thai',
      nameCount: 10,
      translatedCount: 10,
    );
    final dutchHalf = GlAccountTranslation(
      locale: 'nl',
      language: 'Dutch',
      nameCount: 10,
      translatedCount: 5,
    );

    void stubList(List<GlAccountTranslation> list) =>
        when(
          () => restClient.getGlAccountTranslation(start: 0, limit: 20),
        ).thenAnswer(
          (_) async => GlAccountTranslations(glAccountTranslations: list),
        );

    GlAccountTranslationBloc build() => GlAccountTranslationBloc(restClient);

    blocTest<GlAccountTranslationBloc, GlAccountTranslationState>(
      'GlAccountTranslationFetch_initial_showsLoadingThenList',
      setUp: () => stubList([thaiDone, dutchHalf]),
      build: build,
      act: (bloc) => bloc.add(const GlAccountTranslationFetch()),
      wait: fetchWait,
      expect: () => [
        isA<GlAccountTranslationState>().having(
          (s) => s.status,
          'status',
          GlAccountTranslationStatus.loading,
        ),
        isA<GlAccountTranslationState>()
            .having(
              (s) => s.status,
              'status',
              GlAccountTranslationStatus.success,
            )
            .having((s) => s.translations, 'translations', [
              thaiDone,
              dutchHalf,
            ]),
      ],
    );

    blocTest<GlAccountTranslationBloc, GlAccountTranslationState>(
      'GlAccountTranslationFetch_background_usesPollStatusSoDialogStaysOpen',
      setUp: () => stubList([thaiDone]),
      build: build,
      act: (bloc) =>
          bloc.add(const GlAccountTranslationFetch(background: true)),
      wait: fetchWait,
      expect: () => [
        isA<GlAccountTranslationState>().having(
          (s) => s.status,
          'status',
          GlAccountTranslationStatus.pollSuccess,
        ),
      ],
    );

    blocTest<GlAccountTranslationBloc, GlAccountTranslationState>(
      'GlAccountTranslationCreate_language_startsRunAndRefreshesInBackground',
      setUp: () {
        when(
          () => restClient.createGlAccountTranslation(
            sourceLocale: 'en',
            targetLocale: 'nl',
          ),
        ).thenAnswer((_) async => GlAccountTranslations());
        stubList([dutchHalf]);
      },
      build: build,
      act: (bloc) =>
          bloc.add(const GlAccountTranslationCreate(targetLocale: 'nl')),
      wait: fetchWait,
      expect: () => [
        isA<GlAccountTranslationState>().having(
          (s) => s.status,
          'status',
          GlAccountTranslationStatus.loading,
        ),
        isA<GlAccountTranslationState>().having(
          (s) => s.status,
          'status',
          GlAccountTranslationStatus.success,
        ),
        isA<GlAccountTranslationState>()
            .having(
              (s) => s.status,
              'status',
              GlAccountTranslationStatus.pollSuccess,
            )
            .having((s) => s.translations, 'translations', [dutchHalf]),
      ],
    );

    blocTest<GlAccountTranslationBloc, GlAccountTranslationState>(
      'GlAccountTranslationDelete_language_removesAndRefreshes',
      setUp: () {
        when(
          () => restClient.deleteGlAccountTranslation(locale: 'th'),
        ).thenAnswer((_) async {});
        stubList([]);
      },
      build: build,
      act: (bloc) => bloc.add(GlAccountTranslationDelete(thaiDone)),
      wait: fetchWait,
      verify: (bloc) {
        expect(bloc.state.translations, isEmpty);
        verify(
          () => restClient.deleteGlAccountTranslation(locale: 'th'),
        ).called(1);
      },
    );

    blocTest<GlAccountTranslationBloc, GlAccountTranslationState>(
      'GlAccountTranslationCreate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createGlAccountTranslation(
          sourceLocale: 'en',
          targetLocale: 'nl',
        ),
      ).thenThrow(dioError('No AI key')),
      build: build,
      act: (bloc) =>
          bloc.add(const GlAccountTranslationCreate(targetLocale: 'nl')),
      expect: () => [
        isA<GlAccountTranslationState>(),
        isA<GlAccountTranslationState>()
            .having(
              (s) => s.status,
              'status',
              GlAccountTranslationStatus.failure,
            )
            .having((s) => s.message, 'message', 'No AI key'),
      ],
    );
  });
}
