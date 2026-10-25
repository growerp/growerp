import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:support/src/application/blocs/application_bloc.dart';
import 'package:support/src/gl_account_translation/blocs/gl_account_translation_bloc.dart';
import 'package:support/src/website_conversion/blocs/website_conversion_bloc.dart';
import 'package:support/src/website_translation/blocs/website_translation_bloc.dart';

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

  group('WebsiteConversionBloc', () {
    final scraping = WebsiteConversion(
      conversionId: 'W1',
      sourceUrl: 'https://acme.com',
      companyName: 'Acme',
      status: 'SCRAPING',
    );
    final ready = scraping.copyWith(status: 'COMPLETED');

    WebsiteConversionBloc build() => WebsiteConversionBloc(restClient);

    blocTest<WebsiteConversionBloc, WebsiteConversionState>(
      'WebsiteConversionFetch_backgroundCompleted_keepsKnownPassword',
      setUp: () =>
          when(
            () => restClient.getWebsiteConversion(start: 0, limit: 20),
          ).thenAnswer(
            (_) async => WebsiteConversions(websiteConversions: [ready]),
          ),
      build: build,
      seed: () => WebsiteConversionState(
        status: WebsiteConversionStatus.success,
        conversions: [scraping],
        selected: scraping.copyWith(generatedPassword: 'secret'),
      ),
      act: (bloc) => bloc.add(const WebsiteConversionFetch(background: true)),
      wait: fetchWait,
      expect: () => [
        isA<WebsiteConversionState>()
            .having((s) => s.message, 'message', 'Website for Acme is ready')
            .having((s) => s.selected?.status, 'status', 'COMPLETED')
            .having((s) => s.selected?.generatedPassword, 'password', 'secret'),
      ],
    );

    blocTest<WebsiteConversionBloc, WebsiteConversionState>(
      'WebsiteConversionGetOne_id_selectsRowWithPassword',
      setUp: () =>
          when(
            () => restClient.getWebsiteConversion(conversionId: 'W1'),
          ).thenAnswer(
            (_) async => WebsiteConversions(
              websiteConversions: [ready.copyWith(generatedPassword: 'pw')],
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(const WebsiteConversionGetOne('W1')),
      expect: () => [
        isA<WebsiteConversionState>()
            .having(
              (s) => s.status,
              'status',
              WebsiteConversionStatus.pollSuccess,
            )
            .having((s) => s.selected?.generatedPassword, 'password', 'pw'),
      ],
    );

    blocTest<WebsiteConversionBloc, WebsiteConversionState>(
      'WebsiteConversionCreate_site_startsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createWebsiteConversion(
          sourceUrl: 'https://acme.com',
          companyName: 'Acme',
          adminEmail: 'boss@acme.com',
          currencyId: 'THB',
          maxPages: 10,
        ),
      ).thenAnswer((_) async => scraping),
      build: build,
      act: (bloc) => bloc.add(
        const WebsiteConversionCreate(
          sourceUrl: 'https://acme.com',
          companyName: 'Acme',
          adminEmail: 'boss@acme.com',
          currencyId: 'THB',
          maxPages: 10,
        ),
      ),
      expect: () => [
        isA<WebsiteConversionState>(),
        isA<WebsiteConversionState>()
            .having((s) => s.status, 'status', WebsiteConversionStatus.success)
            .having((s) => s.conversions, 'conversions', [scraping]),
      ],
    );

    blocTest<WebsiteConversionBloc, WebsiteConversionState>(
      'WebsiteConversionExport_conversion_setsExportReady',
      setUp: () => when(() => restClient.exportWebsiteOwner(conversionId: 'W1'))
          .thenAnswer(
            (_) async => WebsiteExport(
              xmlText: '<entity-facade-xml/>',
              fileName: 'acme.xml',
              pageCount: 5,
              imageCount: 3,
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(WebsiteConversionExport(ready)),
      expect: () => [
        isA<WebsiteConversionState>(),
        isA<WebsiteConversionState>()
            .having(
              (s) => s.status,
              'status',
              WebsiteConversionStatus.exportReady,
            )
            .having(
              (s) => s.message,
              'message',
              'Exported 5 pages and 3 images',
            )
            .having((s) => s.export?.fileName, 'file', 'acme.xml'),
      ],
    );

    blocTest<WebsiteConversionBloc, WebsiteConversionState>(
      'WebsiteConversionImportFile_xml_installsAndInsertsFirst',
      setUp: () => when(
        () => restClient.importWebsiteFile(
          data: {'xmlText': '<xml/>', 'fileName': 'acme.xml'},
        ),
      ).thenAnswer((_) async => ready),
      build: build,
      act: (bloc) =>
          bloc.add(const WebsiteConversionImportFile('<xml/>', 'acme.xml')),
      expect: () => [
        isA<WebsiteConversionState>(),
        isA<WebsiteConversionState>()
            .having((s) => s.conversions, 'conversions', [ready])
            .having(
              (s) => s.message,
              'message',
              'Website Acme installed from acme.xml',
            ),
      ],
    );

    blocTest<WebsiteConversionBloc, WebsiteConversionState>(
      'WebsiteConversionDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteWebsiteConversion(conversionId: 'W1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => WebsiteConversionState(conversions: [ready]),
      act: (bloc) => bloc.add(WebsiteConversionDelete(ready)),
      expect: () => [
        isA<WebsiteConversionState>(),
        isA<WebsiteConversionState>().having(
          (s) => s.conversions,
          'conversions',
          isEmpty,
        ),
      ],
    );

    blocTest<WebsiteConversionBloc, WebsiteConversionState>(
      'WebsiteConversionCreate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createWebsiteConversion(
          sourceUrl: 'https://acme.com',
          companyName: 'Acme',
          adminEmail: 'boss@acme.com',
          currencyId: 'THB',
        ),
      ).thenThrow(dioError('Email in use')),
      build: build,
      act: (bloc) => bloc.add(
        const WebsiteConversionCreate(
          sourceUrl: 'https://acme.com',
          companyName: 'Acme',
          adminEmail: 'boss@acme.com',
          currencyId: 'THB',
        ),
      ),
      expect: () => [
        isA<WebsiteConversionState>(),
        isA<WebsiteConversionState>()
            .having((s) => s.status, 'status', WebsiteConversionStatus.failure)
            .having((s) => s.message, 'message', 'Email in use'),
      ],
    );
  });
}
