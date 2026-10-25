import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<CredibilityState> credState(
  CredibilityStatus status, {
  List<CredibilityInfo>? elements,
  String? message,
}) {
  var m = isA<CredibilityState>().having((s) => s.status, 'status', status);
  if (elements != null) {
    m = m.having((s) => s.credibilityElements, 'elements', elements);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  const bio = CredibilityInfo(
    credibilityInfoId: 'CI1',
    creatorBio: 'Founder',
    backgroundText: '20 years',
    statistics: [CredibilityStatistic(statistic: 'Clients: 500', sequence: 1)],
  );
  const other = CredibilityInfo(credibilityInfoId: 'CI2', creatorBio: 'Coach');

  setUp(() => restClient = MockRestClient());

  CredibilityBloc build() => CredibilityBloc(restClient: restClient);

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityLoad_page_setsElements',
    setUp: () => when(() => restClient.getCredibilityInfo(landingPageId: 'L1'))
        .thenAnswer(
          (_) async => const CredibilityInfoList(credibilityInfoList: [bio]),
        ),
    build: build,
    act: (bloc) => bloc.add(const CredibilityLoad(landingPageId: 'L1')),
    expect: () => [
      credState(CredibilityStatus.loading),
      credState(CredibilityStatus.success, elements: [bio]),
    ],
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityLoad_restThrowsDio_emitsFailure',
    setUp: () => when(
      () => restClient.getCredibilityInfo(landingPageId: 'L1'),
    ).thenThrow(dioError('No access')),
    build: build,
    act: (bloc) => bloc.add(const CredibilityLoad(landingPageId: 'L1')),
    expect: () => [
      credState(CredibilityStatus.loading),
      credState(CredibilityStatus.failure, message: 'No access'),
    ],
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityInfoCreate_titleAndIcon_sentAsBioAndImageAndInsertedFirst',
    setUp: () => when(
      () => restClient.createCredibilityInfo(
        landingPageId: 'L1',
        creatorBio: 'Coach',
        creatorImageUrl: 'https://x/coach.png',
      ),
    ).thenAnswer((_) async => other),
    build: build,
    seed: () => const CredibilityState(credibilityElements: [bio]),
    act: (bloc) => bloc.add(
      const CredibilityInfoCreate(
        landingPageId: 'L1',
        infoTitle: 'Coach',
        infoIconName: 'https://x/coach.png',
      ),
    ),
    expect: () => [
      credState(CredibilityStatus.loading),
      credState(CredibilityStatus.success, elements: [other, bio]),
    ],
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityInfoUpdate_existing_replacesIt',
    setUp: () =>
        when(
          () => restClient.updateCredibilityInfo(
            landingPageId: 'L1',
            credibilityInfoId: 'CI2',
            creatorBio: 'Head coach',
          ),
        ).thenAnswer(
          (_) async => const CredibilityInfo(
            credibilityInfoId: 'CI2',
            creatorBio: 'Head coach',
          ),
        ),
    build: build,
    seed: () => const CredibilityState(credibilityElements: [bio, other]),
    act: (bloc) => bloc.add(
      const CredibilityInfoUpdate(
        landingPageId: 'L1',
        credibilityInfoId: 'CI2',
        infoTitle: 'Head coach',
      ),
    ),
    expect: () => [
      credState(CredibilityStatus.loading),
      credState(CredibilityStatus.success).having(
        (s) => s.credibilityElements.map((e) => e.creatorBio),
        'bios',
        ['Founder', 'Head coach'],
      ),
    ],
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityInfoDelete_existing_removesIt',
    setUp: () => when(
      () => restClient.deleteCredibilityInfo(
        landingPageId: 'L1',
        credibilityInfoId: 'CI1',
      ),
    ).thenAnswer((_) async {}),
    build: build,
    seed: () => const CredibilityState(credibilityElements: [bio, other]),
    act: (bloc) => bloc.add(
      const CredibilityInfoDelete(
        landingPageId: 'L1',
        credibilityInfoId: 'CI1',
      ),
    ),
    expect: () => [
      credState(CredibilityStatus.loading),
      credState(CredibilityStatus.success, elements: [other]),
    ],
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityStatisticCreate_existingInfo_appendsStatToJson',
    setUp: () => when(
      () => restClient.updateCredibilityInfo(
        landingPageId: 'L1',
        credibilityInfoId: 'CI1',
        creatorBio: 'Founder',
        backgroundText: '20 years',
        statisticsJson: jsonEncode([
          {'statistic': 'Clients: 500', 'sequence': 1},
          {'statistic': 'Years: 20', 'sequence': 2},
        ]),
      ),
    ).thenAnswer((_) async => bio),
    build: build,
    seed: () => const CredibilityState(credibilityElements: [bio]),
    act: (bloc) => bloc.add(
      const CredibilityStatisticCreate(
        landingPageId: 'L1',
        statLabel: 'Years',
        statValue: '20',
      ),
    ),
    expect: () => [
      credState(CredibilityStatus.loading),
      credState(
        CredibilityStatus.success,
        message: 'Credibility statistic created successfully',
      ),
    ],
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityStatisticCreate_noInfoYet_emitsFailureWithoutBackend',
    build: build,
    act: (bloc) => bloc.add(
      const CredibilityStatisticCreate(
        landingPageId: 'L1',
        statLabel: 'Years',
        statValue: '20',
      ),
    ),
    expect: () => [
      credState(CredibilityStatus.loading),
      credState(CredibilityStatus.failure),
    ],
    verify: (_) => verifyZeroInteractions(restClient),
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityStatisticUpdate_any_reportsNotSupported',
    build: build,
    act: (bloc) => bloc.add(
      const CredibilityStatisticUpdate(
        credibilityStatisticId: 'S1',
        statLabel: 'Years',
        statValue: '21',
      ),
    ),
    expect: () => [credState(CredibilityStatus.failure)],
  );

  blocTest<CredibilityBloc, CredibilityState>(
    'CredibilityReorder_newOrder_reordersLocally',
    build: build,
    seed: () => const CredibilityState(credibilityElements: [bio, other]),
    act: (bloc) =>
        bloc.add(const CredibilityReorder(newInfoOrder: ['CI2', 'CI1'])),
    expect: () => [
      isA<CredibilityState>().having((s) => s.credibilityElements, 'elements', [
        other,
        bio,
      ]),
    ],
  );
}
