import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('PersonaBloc', () {
    const founder = Persona(personaId: 'P1', name: 'Founder');
    const cfo = Persona(personaId: 'P2', name: 'CFO');

    TypeMatcher<PersonaState> personaState(
      PersonaStatus status, {
      List<Persona>? personas,
      String? message,
    }) {
      var m = isA<PersonaState>().having((s) => s.status, 'status', status);
      if (personas != null) {
        m = m.having((s) => s.personas, 'personas', personas);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    PersonaBloc build() => PersonaBloc(restClient);

    blocTest<PersonaBloc, PersonaState>(
      'PersonaFetch_initial_loadsFirstPage',
      setUp: () => when(
        () => restClient.getMarketingPersonas(
          start: 0,
          limit: 20,
          searchString: '',
        ),
      ).thenAnswer((_) async => const Personas(personas: [founder, cfo])),
      build: build,
      act: (bloc) => bloc.add(const PersonaFetch()),
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.success, personas: [founder, cfo]),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaFetch_nextPage_appendsWithoutLoadingState',
      setUp: () => when(
        () => restClient.getMarketingPersonas(
          start: 1,
          limit: 20,
          searchString: '',
        ),
      ).thenAnswer((_) async => const Personas(personas: [cfo])),
      build: build,
      seed: () => const PersonaState(
        status: PersonaStatus.success,
        personas: [founder],
      ),
      act: (bloc) => bloc.add(const PersonaFetch()),
      expect: () => [
        personaState(PersonaStatus.success, personas: [founder, cfo]),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getMarketingPersonas(
          start: 0,
          limit: 20,
          searchString: '',
        ),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const PersonaFetch()),
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.failure, message: 'No access'),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaSearchRequested_threeChars_refetchesWithSearch',
      setUp: () => when(
        () => restClient.getMarketingPersonas(
          start: 0,
          limit: 20,
          searchString: 'Fou',
        ),
      ).thenAnswer((_) async => const Personas(personas: [founder])),
      build: build,
      act: (bloc) =>
          bloc.add(const PersonaSearchRequested(searchString: 'Fou')),
      wait: searchWait,
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.success, personas: [founder]),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaCreate_persona_insertsFirst',
      setUp: () => when(
        () => restClient.createMarketingPersona(name: 'CFO', goals: 'Cut cost'),
      ).thenAnswer((_) async => cfo),
      build: build,
      seed: () => const PersonaState(personas: [founder]),
      act: (bloc) => bloc.add(
        const PersonaCreate(Persona(name: 'CFO', goals: 'Cut cost')),
      ),
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.success, personas: [cfo, founder]),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateMarketingPersona(personaId: 'P2', name: 'CFO+'),
      ).thenAnswer((_) async => const Persona(personaId: 'P2', name: 'CFO+')),
      build: build,
      seed: () => const PersonaState(personas: [founder, cfo]),
      act: (bloc) =>
          bloc.add(const PersonaUpdate(Persona(personaId: 'P2', name: 'CFO+'))),
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.success).having(
          (s) => s.personas.map((p) => p.name),
          'names',
          ['Founder', 'CFO+'],
        ),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteMarketingPersona(personaId: 'P1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => const PersonaState(personas: [founder, cfo]),
      act: (bloc) => bloc.add(const PersonaDelete(founder)),
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.success, personas: [cfo]),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaGenerateWithAI_description_insertsGeneratedFirst',
      setUp: () => when(
        () => restClient.generateMarketingPersonaWithAI(
          businessDescription: 'ERP for SMEs',
          targetMarket: 'Thailand',
        ),
      ).thenAnswer((_) async => cfo),
      build: build,
      seed: () => const PersonaState(personas: [founder]),
      act: (bloc) => bloc.add(
        const PersonaGenerateWithAI(
          businessDescription: 'ERP for SMEs',
          targetMarket: 'Thailand',
        ),
      ),
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.success, personas: [cfo, founder]),
      ],
    );

    blocTest<PersonaBloc, PersonaState>(
      'PersonaGenerateWithAI_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.generateMarketingPersonaWithAI(
          businessDescription: 'ERP for SMEs',
        ),
      ).thenThrow(dioError('Model overloaded')),
      build: build,
      act: (bloc) => bloc.add(
        const PersonaGenerateWithAI(businessDescription: 'ERP for SMEs'),
      ),
      expect: () => [
        personaState(PersonaStatus.loading),
        personaState(PersonaStatus.failure, message: 'Model overloaded'),
      ],
    );
  });

  group('ContentPlanBloc', () {
    final week1 = ContentPlan(planId: 'CP1', theme: 'Launch');
    final week2 = ContentPlan(planId: 'CP2', theme: 'Follow up');

    TypeMatcher<ContentPlanState> planState(
      ContentPlanStatus status, {
      List<ContentPlan>? plans,
      String? message,
    }) {
      var m = isA<ContentPlanState>().having((s) => s.status, 'status', status);
      if (plans != null) m = m.having((s) => s.contentPlans, 'plans', plans);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    ContentPlanBloc build() => ContentPlanBloc(restClient);

    blocTest<ContentPlanBloc, ContentPlanState>(
      'ContentPlanFetch_initial_loadsFirstPage',
      setUp: () => when(
        () => restClient.getContentPlans(start: 0, limit: 20, searchString: ''),
      ).thenAnswer((_) async => ContentPlans(contentPlans: [week1, week2])),
      build: build,
      act: (bloc) => bloc.add(const ContentPlanFetch()),
      expect: () => [
        planState(ContentPlanStatus.loading),
        planState(ContentPlanStatus.success, plans: [week1, week2]),
      ],
    );

    blocTest<ContentPlanBloc, ContentPlanState>(
      'ContentPlanFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getContentPlans(start: 0, limit: 20, searchString: ''),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const ContentPlanFetch()),
      expect: () => [
        planState(ContentPlanStatus.loading),
        planState(ContentPlanStatus.failure, message: 'No access'),
      ],
    );

    blocTest<ContentPlanBloc, ContentPlanState>(
      'ContentPlanCreate_withDate_sendsInstantAsEpochMillis',
      setUp: () => when(
        () => restClient.createContentPlan(
          personaId: 'P1',
          weekStartDate: DateTime.utc(2026, 11, 2).millisecondsSinceEpoch,
          theme: 'Launch',
        ),
      ).thenAnswer((_) async => week1),
      build: build,
      seed: () => ContentPlanState(contentPlans: [week2]),
      act: (bloc) => bloc.add(
        ContentPlanCreate(
          ContentPlan(
            personaId: 'P1',
            weekStartDate: DateTime.utc(2026, 11, 2),
            theme: 'Launch',
          ),
        ),
      ),
      expect: () => [
        planState(ContentPlanStatus.loading),
        planState(ContentPlanStatus.success, plans: [week1, week2]),
      ],
    );

    blocTest<ContentPlanBloc, ContentPlanState>(
      'ContentPlanUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateContentPlan(planId: 'CP2', theme: 'Retarget'),
      ).thenAnswer((_) async => ContentPlan(planId: 'CP2', theme: 'Retarget')),
      build: build,
      seed: () => ContentPlanState(contentPlans: [week1, week2]),
      act: (bloc) => bloc.add(
        ContentPlanUpdate(ContentPlan(planId: 'CP2', theme: 'Retarget')),
      ),
      expect: () => [
        planState(ContentPlanStatus.loading),
        planState(ContentPlanStatus.success).having(
          (s) => s.contentPlans.map((p) => p.theme),
          'themes',
          ['Launch', 'Retarget'],
        ),
      ],
    );

    blocTest<ContentPlanBloc, ContentPlanState>(
      'ContentPlanDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteContentPlan(planId: 'CP1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => ContentPlanState(contentPlans: [week1, week2]),
      act: (bloc) => bloc.add(ContentPlanDelete(week1)),
      expect: () => [
        planState(ContentPlanStatus.loading),
        planState(ContentPlanStatus.success, plans: [week2]),
      ],
    );

    blocTest<ContentPlanBloc, ContentPlanState>(
      'ContentPlanGenerateWithAI_localDate_sendsUtcMidnightOfThatDay',
      setUp: () => when(
        () => restClient.generateContentPlanWithAI(
          personaId: 'P1',
          weekStartDate: DateTime.utc(2026, 11, 2).millisecondsSinceEpoch,
          weeks: 4,
          planFormat: 'WEEKLY',
        ),
      ).thenAnswer((_) async => week1),
      build: build,
      act: (bloc) => bloc.add(
        ContentPlanGenerateWithAI(
          personaId: 'P1',
          weekStartDate: DateTime(2026, 11, 2, 15, 30), // local, any time
          weeks: 4,
          planFormat: 'WEEKLY',
        ),
      ),
      expect: () => [
        planState(ContentPlanStatus.loading),
        planState(ContentPlanStatus.success, plans: [week1]),
      ],
    );

    blocTest<ContentPlanBloc, ContentPlanState>(
      'ContentPlanSearchRequested_threeChars_refetchesWithSearch',
      setUp: () => when(
        () => restClient.getContentPlans(
          start: 0,
          limit: 20,
          searchString: 'Lau',
        ),
      ).thenAnswer((_) async => ContentPlans(contentPlans: [week1])),
      build: build,
      act: (bloc) =>
          bloc.add(const ContentPlanSearchRequested(searchString: 'Lau')),
      wait: searchWait,
      expect: () => [
        planState(ContentPlanStatus.loading),
        planState(ContentPlanStatus.success, plans: [week1]),
      ],
    );
  });
}
