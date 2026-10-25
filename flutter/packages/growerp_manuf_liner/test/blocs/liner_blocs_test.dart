import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_manuf_liner/growerp_manuf_liner.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// Fetch events are throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('LinerTypeBloc', () {
    final pvc = LinerType(linerTypeId: 'T1', linerName: 'PVC 30');
    final hdpe = LinerType(linerTypeId: 'T2', linerName: 'HDPE 40');

    TypeMatcher<LinerTypeState> typeState(
      LinerTypeStatus status, {
      List<LinerType>? types,
      String? message,
    }) {
      var m = isA<LinerTypeState>().having((s) => s.status, 'status', status);
      if (types != null) m = m.having((s) => s.linerTypes, 'types', types);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    LinerTypeBloc build() => LinerTypeBloc(restClient);

    blocTest<LinerTypeBloc, LinerTypeState>(
      'LinerTypesFetch_refresh_loadsFirstPage',
      setUp: () => when(
        () => restClient.getLinerTypes(start: 0, limit: 20),
      ).thenAnswer((_) async => LinerTypes(linerTypes: [pvc, hdpe])),
      build: build,
      act: (bloc) => bloc.add(const LinerTypesFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        typeState(LinerTypeStatus.loading),
        typeState(LinerTypeStatus.success, types: [pvc, hdpe]),
      ],
    );

    blocTest<LinerTypeBloc, LinerTypeState>(
      'LinerTypesFetch_newSearch_restartsWithSearch',
      setUp: () => when(
        () => restClient.getLinerTypes(search: 'PVC', start: 0, limit: 20),
      ).thenAnswer((_) async => LinerTypes(linerTypes: [pvc])),
      build: build,
      seed: () => LinerTypeState(linerTypes: [pvc, hdpe], hasReachedMax: true),
      act: (bloc) => bloc.add(const LinerTypesFetch(searchString: 'PVC')),
      wait: fetchWait,
      expect: () => [
        typeState(LinerTypeStatus.loading),
        typeState(LinerTypeStatus.success, types: [pvc]),
      ],
    );

    blocTest<LinerTypeBloc, LinerTypeState>(
      'LinerTypesFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getLinerTypes(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const LinerTypesFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        typeState(LinerTypeStatus.loading),
        typeState(LinerTypeStatus.failure), // shows raw exception text
      ],
    );

    blocTest<LinerTypeBloc, LinerTypeState>(
      'LinerTypeUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createLinerType(
          linerType: LinerType(linerName: 'HDPE 40'),
        ),
      ).thenAnswer((_) async => hdpe),
      build: build,
      seed: () => LinerTypeState(linerTypes: [pvc]),
      act: (bloc) => bloc.add(LinerTypeUpdate(LinerType(linerName: 'HDPE 40'))),
      expect: () => [
        typeState(LinerTypeStatus.loading),
        typeState(LinerTypeStatus.success, types: [hdpe, pvc]),
      ],
    );

    blocTest<LinerTypeBloc, LinerTypeState>(
      'LinerTypeDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteLinerType(linerType: pvc),
      ).thenAnswer((_) async => pvc),
      build: build,
      seed: () => LinerTypeState(linerTypes: [pvc, hdpe]),
      act: (bloc) => bloc.add(LinerTypeDelete(pvc)),
      expect: () => [
        typeState(LinerTypeStatus.loading),
        typeState(LinerTypeStatus.success, types: [hdpe]),
      ],
    );
  });

  group('LinerPanelBloc', () {
    final panel1 = LinerPanel(qcNum: 'QC1', workEffortId: 'W1');
    final panel2 = LinerPanel(qcNum: 'QC2', workEffortId: 'W1');

    TypeMatcher<LinerPanelState> panelState(
      LinerPanelStatus status, {
      List<LinerPanel>? panels,
      String? message,
    }) {
      var m = isA<LinerPanelState>().having((s) => s.status, 'status', status);
      if (panels != null) m = m.having((s) => s.linerPanels, 'panels', panels);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    LinerPanelBloc build() => LinerPanelBloc(restClient);

    blocTest<LinerPanelBloc, LinerPanelState>(
      'LinerPanelsFetch_otherWorkOrder_restartsForThatFilter',
      setUp: () => when(
        () =>
            restClient.getLinerPanels(workEffortId: 'W1', start: 0, limit: 100),
      ).thenAnswer((_) async => LinerPanels(linerPanels: [panel1, panel2])),
      build: build,
      seed: () => LinerPanelState(
        workEffortId: 'W9',
        linerPanels: [LinerPanel(qcNum: 'X')],
        hasReachedMax: true,
      ),
      act: (bloc) => bloc.add(const LinerPanelsFetch(workEffortId: 'W1')),
      wait: fetchWait,
      expect: () => [
        panelState(LinerPanelStatus.loading),
        panelState(
          LinerPanelStatus.success,
          panels: [panel1, panel2],
        ).having((s) => s.workEffortId, 'workEffortId', 'W1'),
      ],
    );

    blocTest<LinerPanelBloc, LinerPanelState>(
      'LinerPanelsFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () =>
            restClient.getLinerPanels(workEffortId: 'W1', start: 0, limit: 100),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const LinerPanelsFetch(workEffortId: 'W1')),
      wait: fetchWait,
      expect: () => [
        panelState(LinerPanelStatus.loading),
        panelState(LinerPanelStatus.failure), // shows raw exception text
      ],
    );

    blocTest<LinerPanelBloc, LinerPanelState>(
      'LinerPanelUpdate_newPanel_createsAndAppendsInQcOrder',
      setUp: () => when(
        () => restClient.createLinerPanel(
          linerPanel: LinerPanel(workEffortId: 'W1'),
        ),
      ).thenAnswer((_) async => panel2),
      build: build,
      seed: () => LinerPanelState(linerPanels: [panel1]),
      act: (bloc) => bloc.add(LinerPanelUpdate(LinerPanel(workEffortId: 'W1'))),
      expect: () => [
        panelState(LinerPanelStatus.loading),
        panelState(LinerPanelStatus.success, panels: [panel1, panel2]),
      ],
    );

    blocTest<LinerPanelBloc, LinerPanelState>(
      'LinerPanelUpdate_existing_replacesByQcNum',
      setUp: () => when(
        () => restClient.updateLinerPanel(
          linerPanel: panel1.copyWith(linerName: 'Pond'),
        ),
      ).thenAnswer((_) async => panel1.copyWith(linerName: 'Pond')),
      build: build,
      seed: () => LinerPanelState(linerPanels: [panel1, panel2]),
      act: (bloc) =>
          bloc.add(LinerPanelUpdate(panel1.copyWith(linerName: 'Pond'))),
      expect: () => [
        panelState(LinerPanelStatus.loading),
        panelState(
          LinerPanelStatus.success,
          panels: [
            panel1.copyWith(linerName: 'Pond'),
            panel2,
          ],
        ),
      ],
    );

    blocTest<LinerPanelBloc, LinerPanelState>(
      'LinerPanelDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteLinerPanel(linerPanel: panel1),
      ).thenAnswer((_) async => panel1),
      build: build,
      seed: () => LinerPanelState(linerPanels: [panel1, panel2]),
      act: (bloc) => bloc.add(LinerPanelDelete(panel1)),
      expect: () => [
        panelState(LinerPanelStatus.loading),
        panelState(LinerPanelStatus.success, panels: [panel2]),
      ],
    );
  });
}
