import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<LandingPageState> pageState(
  LandingPageStatus status, {
  List<LandingPage>? pages,
  String? message,
}) {
  var m = isA<LandingPageState>().having((s) => s.status, 'status', status);
  if (pages != null) m = m.having((s) => s.landingPages, 'landingPages', pages);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  const page1 = LandingPage(
    landingPageId: 'L1',
    pseudoId: 'lp1',
    title: 'Scorecard',
    status: 'ACTIVE',
  );
  const page2 = LandingPage(
    landingPageId: 'L2',
    pseudoId: 'lp2',
    title: 'Webinar',
    status: 'DRAFT',
  );

  setUp(() => restClient = MockRestClient());

  LandingPageBloc build() =>
      LandingPageBloc(restClient: restClient, applicationId: 'AppAdmin');

  group('LandingPageLoad', () {
    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageLoad_firstPage_clearsThenEmitsPages',
      setUp: () => when(() => restClient.getLandingPages(start: 0, limit: 20))
          .thenAnswer(
            (_) async => const LandingPages(landingPages: [page1, page2]),
          ),
      build: build,
      act: (bloc) => bloc.add(const LandingPageLoad()),
      expect: () => [
        pageState(LandingPageStatus.loading, pages: []),
        pageState(
          LandingPageStatus.success,
          pages: [page1, page2],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageLoad_nextPage_appends',
      setUp: () => when(
        () => restClient.getLandingPages(start: 1, limit: 1),
      ).thenAnswer((_) async => const LandingPages(landingPages: [page2])),
      build: build,
      seed: () => const LandingPageState(
        status: LandingPageStatus.success,
        landingPages: [page1],
      ),
      act: (bloc) => bloc.add(const LandingPageLoad(start: 1, limit: 1)),
      expect: () => [
        pageState(LandingPageStatus.success, pages: [page1, page2]),
      ],
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageLoad_nextPageAfterMax_doesNothing',
      build: build,
      seed: () =>
          const LandingPageState(landingPages: [page1], hasReachedMax: true),
      act: (bloc) => bloc.add(const LandingPageLoad(start: 1)),
      expect: () => <LandingPageState>[],
      verify: (_) => verifyZeroInteractions(restClient),
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageLoad_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getLandingPages(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const LandingPageLoad()),
      expect: () => [
        pageState(LandingPageStatus.loading),
        pageState(LandingPageStatus.failure, message: 'No access'),
      ],
    );
  });

  blocTest<LandingPageBloc, LandingPageState>(
    'LandingPageSearchRequested_threeChars_loadsFirstPageWithSearch',
    setUp: () => when(
      () =>
          restClient.getLandingPages(start: 0, limit: 20, searchString: 'Sco'),
    ).thenAnswer((_) async => const LandingPages(landingPages: [page1])),
    build: build,
    act: (bloc) => bloc.add(const LandingPageSearchRequested(query: 'Sco')),
    wait: const Duration(milliseconds: 400),
    expect: () => [
      pageState(LandingPageStatus.loading),
      pageState(LandingPageStatus.success, pages: [page1]),
    ],
  );

  group('LandingPageFetch', () {
    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageFetch_pseudoId_setsSelectedPage',
      setUp: () => when(
        () => restClient.getLandingPage(pseudoId: 'lp1', ownerPartyId: 'O1'),
      ).thenAnswer((_) async => page1),
      build: build,
      act: (bloc) =>
          bloc.add(const LandingPageFetch(pseudoId: 'lp1', ownerPartyId: 'O1')),
      expect: () => [
        pageState(LandingPageStatus.loading),
        pageState(
          LandingPageStatus.success,
        ).having((s) => s.selectedLandingPage, 'selected', page1),
      ],
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getLandingPage(landingPageId: 'L9'),
      ).thenThrow(dioError('Not found')),
      build: build,
      act: (bloc) => bloc.add(const LandingPageFetch(landingPageId: 'L9')),
      expect: () => [
        pageState(LandingPageStatus.loading),
        pageState(LandingPageStatus.failure, message: 'Not found'),
      ],
    );
  });

  group('LandingPageCreate / Update / Delete', () {
    const newPage = LandingPage(
      title: 'Webinar',
      status: 'DRAFT',
      theme: 'dark',
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageCreate_page_insertsFirstAndSelectsIt',
      setUp: () => when(
        () => restClient.createLandingPage(
          title: 'Webinar',
          status: 'DRAFT',
          theme: 'dark',
        ),
      ).thenAnswer((_) async => page2),
      build: build,
      seed: () => const LandingPageState(landingPages: [page1]),
      act: (bloc) => bloc.add(const LandingPageCreate(newPage)),
      expect: () => [
        pageState(LandingPageStatus.loading),
        pageState(
          LandingPageStatus.success,
          pages: [page2, page1],
          message: 'Landing page created successfully',
        ).having((s) => s.selectedLandingPage, 'selected', page2),
      ],
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageUpdate_page_replacesItInList',
      setUp: () => when(
        () => restClient.updateLandingPage(
          landingPageId: 'L2',
          pseudoId: 'lp2',
          title: 'Webinar 2',
          status: 'DRAFT',
        ),
      ).thenAnswer((_) async => page2.copyWith(title: 'Webinar 2')),
      build: build,
      seed: () => const LandingPageState(landingPages: [page1, page2]),
      act: (bloc) =>
          bloc.add(LandingPageUpdate(page2.copyWith(title: 'Webinar 2'))),
      expect: () => [
        pageState(LandingPageStatus.loading),
        pageState(
          LandingPageStatus.success,
          pages: [
            page1,
            page2.copyWith(title: 'Webinar 2'),
          ],
          message: 'Landing page updated successfully',
        ),
      ],
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageDelete_page_removesItAndClearsSelection',
      setUp: () => when(
        () => restClient.deleteLandingPage(landingPageId: 'L1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => const LandingPageState(
        landingPages: [page1, page2],
        selectedLandingPage: page1,
      ),
      act: (bloc) => bloc.add(const LandingPageDelete('L1')),
      expect: () => [
        pageState(LandingPageStatus.loading),
        pageState(
          LandingPageStatus.success,
          pages: [page2],
          message: 'Landing page deleted successfully',
        ).having((s) => s.selectedLandingPage, 'selected', isNull),
      ],
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageCreate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createLandingPage(
          title: 'Webinar',
          status: 'DRAFT',
          theme: 'dark',
        ),
      ).thenThrow(dioError('pseudoId taken')),
      build: build,
      act: (bloc) => bloc.add(const LandingPageCreate(newPage)),
      expect: () => [
        pageState(LandingPageStatus.loading),
        pageState(LandingPageStatus.failure, message: 'pseudoId taken'),
      ],
    );

    blocTest<LandingPageBloc, LandingPageState>(
      'LandingPageClear_selected_clearsSelection',
      build: build,
      seed: () => const LandingPageState(selectedLandingPage: page1),
      act: (bloc) => bloc.add(const LandingPageClear()),
      expect: () => [
        isA<LandingPageState>().having(
          (s) => s.selectedLandingPage,
          'selected',
          isNull,
        ),
      ],
    );
  });

  group('PageSectionBloc', () {
    const intro = LandingPageSection(
      landingPageSectionId: 'S1',
      sectionTitle: 'Intro',
      sectionSequence: 10,
    );
    const stats = LandingPageSection(
      landingPageSectionId: 'S2',
      sectionTitle: 'Stats',
      sectionSequence: 20,
    );

    PageSectionBloc build() => PageSectionBloc(restClient: restClient);

    blocTest<PageSectionBloc, PageSectionState>(
      'PageSectionLoad_page_setsSectionsAndPageId',
      setUp: () => when(() => restClient.getPageSections(landingPageId: 'L1'))
          .thenAnswer(
            (_) async => const LandingPageSections(sections: [intro, stats]),
          ),
      build: build,
      act: (bloc) => bloc.add(const PageSectionLoad('L1')),
      expect: () => [
        isA<PageSectionState>().having(
          (s) => s.status,
          'status',
          PageSectionStatus.loading,
        ),
        isA<PageSectionState>()
            .having((s) => s.sections, 'sections', [intro, stats])
            .having((s) => s.pageId, 'pageId', 'L1'),
      ],
    );

    blocTest<PageSectionBloc, PageSectionState>(
      'PageSectionCreate_middleSequence_insertsSortedBySequence',
      setUp: () =>
          when(
            () => restClient.createPageSection(
              landingPageId: 'L1',
              sectionTitle: 'Middle',
              sectionSequence: 15,
            ),
          ).thenAnswer(
            (_) async => const LandingPageSection(
              landingPageSectionId: 'S3',
              sectionTitle: 'Middle',
              sectionSequence: 15,
            ),
          ),
      build: build,
      seed: () =>
          const PageSectionState(pageId: 'L1', sections: [intro, stats]),
      act: (bloc) => bloc.add(
        const PageSectionCreate(
          landingPageId: 'L1',
          sectionTitle: 'Middle',
          sectionSequence: 15,
        ),
      ),
      expect: () => [
        isA<PageSectionState>(),
        isA<PageSectionState>().having(
          (s) => s.sections.map((x) => x.sectionTitle),
          'titles',
          ['Intro', 'Middle', 'Stats'],
        ),
      ],
    );

    blocTest<PageSectionBloc, PageSectionState>(
      'PageSectionUpdate_newSequence_replacesAndResorts',
      setUp: () =>
          when(
            () => restClient.updatePageSection(
              landingPageId: 'L1',
              pageSectionId: 'S1',
              sectionSequence: 30,
            ),
          ).thenAnswer(
            (_) async => const LandingPageSection(
              landingPageSectionId: 'S1',
              sectionTitle: 'Intro',
              sectionSequence: 30,
            ),
          ),
      build: build,
      seed: () =>
          const PageSectionState(pageId: 'L1', sections: [intro, stats]),
      act: (bloc) => bloc.add(
        const PageSectionUpdate(pageSectionId: 'S1', sectionSequence: 30),
      ),
      expect: () => [
        isA<PageSectionState>(),
        isA<PageSectionState>()
            .having((s) => s.sections.map((x) => x.sectionTitle), 'titles', [
              'Stats',
              'Intro',
            ])
            .having(
              (s) => s.message,
              'message',
              'Section updated successfully',
            ),
      ],
    );

    blocTest<PageSectionBloc, PageSectionState>(
      'PageSectionDelete_section_removesIt',
      setUp: () => when(
        () => restClient.deletePageSection(
          landingPageId: 'L1',
          pageSectionId: 'S1',
        ),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () =>
          const PageSectionState(pageId: 'L1', sections: [intro, stats]),
      act: (bloc) => bloc.add(const PageSectionDelete('S1')),
      expect: () => [
        isA<PageSectionState>(),
        isA<PageSectionState>().having((s) => s.sections, 'sections', [stats]),
      ],
    );

    blocTest<PageSectionBloc, PageSectionState>(
      'PageSectionLoad_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getPageSections(landingPageId: 'L1'),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const PageSectionLoad('L1')),
      expect: () => [
        isA<PageSectionState>(),
        isA<PageSectionState>()
            .having((s) => s.status, 'status', PageSectionStatus.failure)
            .having((s) => s.message, 'message', 'No access'),
      ],
    );
  });

  group('LandingPageGenerationBloc', () {
    LandingPageGenerationBloc build() => LandingPageGenerationBloc(
      restClient: restClient,
      applicationId: 'AppAdmin',
    );

    blocTest<LandingPageGenerationBloc, LandingPageGenerationState>(
      'GenerateLandingPageRequested_defaults_sendsToneAndSectionsAndReturnsPage',
      setUp: () =>
          when(
            () => restClient.generateLandingPageWithAI(
              businessDescription: 'We sell coffee',
              tone: 'professional',
              numSections: 5,
            ),
          ).thenAnswer(
            (_) async => LandingPageGenerationResponse(landingPage: page1),
          ),
      build: build,
      act: (bloc) => bloc.add(
        const GenerateLandingPageRequested(
          businessDescription: 'We sell coffee',
        ),
      ),
      expect: () => [
        isA<LandingPageGenerationState>().having(
          (s) => s.status,
          'status',
          GenerationStatus.loading,
        ),
        isA<LandingPageGenerationState>().having(
          (s) => s.status,
          'status',
          GenerationStatus.researchingBusiness,
        ),
        isA<LandingPageGenerationState>()
            .having((s) => s.status, 'status', GenerationStatus.success)
            .having((s) => s.progressPercent, 'progress', 100)
            .having((s) => s.generatedLandingPage, 'page', page1),
      ],
    );

    blocTest<LandingPageGenerationBloc, LandingPageGenerationState>(
      'GenerateLandingPageRequested_aiFails_emitsFailureAndResetsProgress',
      setUp: () => when(
        () => restClient.generateLandingPageWithAI(
          businessDescription: 'We sell coffee',
          tone: 'professional',
          numSections: 5,
        ),
      ).thenThrow(dioError('Model overloaded')),
      build: build,
      act: (bloc) => bloc.add(
        const GenerateLandingPageRequested(
          businessDescription: 'We sell coffee',
        ),
      ),
      skip: 2,
      expect: () => [
        isA<LandingPageGenerationState>()
            .having((s) => s.status, 'status', GenerationStatus.failure)
            .having((s) => s.message, 'message', 'Model overloaded')
            .having((s) => s.progressPercent, 'progress', 0),
      ],
    );

    blocTest<LandingPageGenerationBloc, LandingPageGenerationState>(
      'GenerationCancelled_any_resetsToInitial',
      build: build,
      seed: () => const LandingPageGenerationState(
        status: GenerationStatus.researchingBusiness,
      ),
      act: (bloc) => bloc.add(const GenerationCancelled()),
      expect: () => [
        isA<LandingPageGenerationState>().having(
          (s) => s.status,
          'status',
          GenerationStatus.initial,
        ),
      ],
    );
  });
}
