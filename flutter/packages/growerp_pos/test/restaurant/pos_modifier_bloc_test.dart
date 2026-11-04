import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final group = PosModifierGroup(groupId: 'G1', groupName: 'Sauce');

  setUp(() {
    restClient = MockRestClient();
    when(
      () => restClient.getPosModifierGroups(),
    ).thenAnswer((_) async => PosModifierGroups(modifierGroups: [group]));
  });

  blocTest<PosModifierBloc, PosModifierState>(
    'PosModifierFetch_givesTheGroups',
    build: () => PosModifierBloc(restClient),
    act: (bloc) => bloc.add(const PosModifierFetch()),
    expect: () => [
      isA<PosModifierState>()
          .having((s) => s.groups, 'groups', [group])
          .having((s) => s.message, 'message', isNull),
    ],
  );

  blocTest<PosModifierBloc, PosModifierState>(
    'PosModifierSave_storesAndReloads',
    setUp: () => when(
      () => restClient.storePosModifierGroup(group: group),
    ).thenAnswer((_) async => group),
    build: () => PosModifierBloc(restClient),
    act: (bloc) => bloc.add(PosModifierSave(group)),
    expect: () => [
      isA<PosModifierState>().having((s) => s.message, 'message', 'saved'),
    ],
  );

  blocTest<PosModifierBloc, PosModifierState>(
    'PosModifierDelete_restError_failure',
    setUp: () => when(
      () => restClient.deletePosModifierGroup(groupId: 'G1'),
    ).thenThrow(dioError('in use')),
    build: () => PosModifierBloc(restClient),
    act: (bloc) => bloc.add(const PosModifierDelete('G1')),
    expect: () => [
      isA<PosModifierState>().having(
        (s) => s.status,
        'status',
        PosModifierStatus.failure,
      ),
    ],
  );
}
