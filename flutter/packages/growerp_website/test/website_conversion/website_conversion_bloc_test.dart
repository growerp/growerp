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
      'WebsiteConversionCreate_targetStore_sendsOnlyUrlAndPages',
      setUp: () => when(
        () => restClient.createWebsiteConversion(
          sourceUrl: 'https://acme.com',
          targetStore: true,
          maxPages: 6,
        ),
      ).thenAnswer((_) async => scraping),
      build: build,
      act: (bloc) => bloc.add(
        const WebsiteConversionCreate(
          sourceUrl: 'https://acme.com',
          targetStore: true,
          maxPages: 6,
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
