import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_manufacturing/growerp_manufacturing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// Fetch events are throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('WorkOrderBloc', () {
    final wo1 = WorkOrder(workEffortId: 'W1', workEffortName: 'Batch 1');
    final wo2 = WorkOrder(workEffortId: 'W2', workEffortName: 'Batch 2');

    TypeMatcher<WorkOrderState> woState(
      WorkOrderStatus status, {
      List<WorkOrder>? orders,
      String? message,
    }) {
      var m = isA<WorkOrderState>().having((s) => s.status, 'status', status);
      if (orders != null) m = m.having((s) => s.workOrders, 'orders', orders);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    WorkOrderBloc build() => WorkOrderBloc(restClient);

    blocTest<WorkOrderBloc, WorkOrderState>(
      'WorkOrderFetch_initial_loadsFirstPage',
      setUp: () => when(
        () => restClient.getWorkOrder(search: '', start: 0, limit: 20),
      ).thenAnswer((_) async => WorkOrders(workOrders: [wo1, wo2])),
      build: build,
      act: (bloc) => bloc.add(const WorkOrderFetch()),
      wait: fetchWait,
      expect: () => [
        woState(WorkOrderStatus.loading),
        woState(WorkOrderStatus.success, orders: [wo1, wo2]),
      ],
    );

    blocTest<WorkOrderBloc, WorkOrderState>(
      'WorkOrderFetch_nextPage_appends',
      setUp: () => when(
        () => restClient.getWorkOrder(search: '', start: 1, limit: 20),
      ).thenAnswer((_) async => WorkOrders(workOrders: [wo2])),
      build: build,
      seed: () =>
          WorkOrderState(status: WorkOrderStatus.success, workOrders: [wo1]),
      act: (bloc) => bloc.add(const WorkOrderFetch()),
      wait: fetchWait,
      expect: () => [
        woState(WorkOrderStatus.loading),
        woState(WorkOrderStatus.success, orders: [wo1, wo2]),
      ],
    );

    blocTest<WorkOrderBloc, WorkOrderState>(
      'WorkOrderFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getWorkOrder(search: '', start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const WorkOrderFetch()),
      wait: fetchWait,
      expect: () => [
        woState(WorkOrderStatus.loading),
        woState(WorkOrderStatus.failure, orders: [], message: 'No access'),
      ],
    );

    blocTest<WorkOrderBloc, WorkOrderState>(
      'WorkOrderUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createWorkOrder(
          workOrder: WorkOrder(workEffortName: 'Batch 2'),
        ),
      ).thenAnswer((_) async => wo2),
      build: build,
      seed: () => WorkOrderState(workOrders: [wo1]),
      act: (bloc) =>
          bloc.add(WorkOrderUpdate(WorkOrder(workEffortName: 'Batch 2'))),
      expect: () => [
        woState(WorkOrderStatus.success, orders: [wo2, wo1]),
      ],
    );

    blocTest<WorkOrderBloc, WorkOrderState>(
      'WorkOrderUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateWorkOrder(
          workOrder: wo2.copyWith(workEffortName: 'Batch 2b'),
        ),
      ).thenAnswer((_) async => wo2.copyWith(workEffortName: 'Batch 2b')),
      build: build,
      seed: () => WorkOrderState(workOrders: [wo1, wo2]),
      act: (bloc) =>
          bloc.add(WorkOrderUpdate(wo2.copyWith(workEffortName: 'Batch 2b'))),
      expect: () => [
        woState(
          WorkOrderStatus.success,
          orders: [
            wo1,
            wo2.copyWith(workEffortName: 'Batch 2b'),
          ],
        ),
      ],
    );

    blocTest<WorkOrderBloc, WorkOrderState>(
      'WorkOrderDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteWorkOrder(workOrder: wo1),
      ).thenAnswer((_) async => wo1),
      build: build,
      seed: () => WorkOrderState(workOrders: [wo1, wo2]),
      act: (bloc) => bloc.add(WorkOrderDelete(wo1)),
      expect: () => [
        woState(WorkOrderStatus.success, orders: [wo2]),
      ],
    );

    blocTest<WorkOrderBloc, WorkOrderState>(
      'WorkOrderDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteWorkOrder(workOrder: wo1),
      ).thenThrow(dioError('Already started')),
      build: build,
      seed: () => WorkOrderState(workOrders: [wo1]),
      act: (bloc) => bloc.add(WorkOrderDelete(wo1)),
      expect: () => [
        woState(WorkOrderStatus.failure, message: 'Already started'),
      ],
    );
  });

  group('BomBloc', () {
    final bike = Bom(productId: 'P1', productName: 'Bike');
    final wheel = BomItem(
      productId: 'P1',
      toProductId: 'C1',
      fromDate: '2026-01-01',
    );
    final frame = BomItem(productId: 'P1', toProductId: 'C2');

    TypeMatcher<BomState> bomState(BomStatus status, {String? message}) {
      var m = isA<BomState>().having((s) => s.status, 'status', status);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    BomBloc build() => BomBloc(restClient);

    blocTest<BomBloc, BomState>(
      'BomsFetch_initial_listsAssemblies',
      setUp: () => when(
        () => restClient.getBoms(start: 0, limit: 20),
      ).thenAnswer((_) async => Boms(boms: [bike])),
      build: build,
      act: (bloc) => bloc.add(const BomsFetch()),
      wait: fetchWait,
      expect: () => [
        bomState(BomStatus.loading),
        bomState(BomStatus.success).having((s) => s.boms, 'boms', [bike]),
      ],
    );

    blocTest<BomBloc, BomState>(
      'BomFetch_otherProduct_restartsFromFirstItem',
      setUp: () => when(
        () => restClient.getBomItem(
          productId: 'P1',
          search: '',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer((_) async => BomItems(bomItems: [wheel, frame])),
      build: build,
      seed: () => BomState(
        status: BomStatus.success,
        productId: 'P9',
        bomItems: [BomItem(productId: 'P9', toProductId: 'X')],
      ),
      act: (bloc) => bloc.add(const BomFetch(productId: 'P1')),
      wait: fetchWait,
      expect: () => [
        bomState(BomStatus.loading),
        bomState(BomStatus.success)
            .having((s) => s.bomItems, 'items', [wheel, frame])
            .having((s) => s.productId, 'productId', 'P1'),
      ],
    );

    blocTest<BomBloc, BomState>(
      'BomFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getBomItem(
          productId: 'P1',
          search: '',
          start: 0,
          limit: 20,
        ),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const BomFetch(productId: 'P1')),
      wait: fetchWait,
      expect: () => [
        bomState(BomStatus.loading),
        bomState(BomStatus.failure, message: 'No access'),
      ],
    );

    blocTest<BomBloc, BomState>(
      'BomUpdate_noFromDate_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createBomItem(bomItem: frame),
      ).thenAnswer((_) async => frame.copyWith(fromDate: '2026-10-25')),
      build: build,
      seed: () => BomState(bomItems: [wheel]),
      act: (bloc) => bloc.add(BomUpdate(frame)),
      expect: () => [
        bomState(BomStatus.success).having(
          (s) => s.bomItems.map((i) => i.toProductId),
          'components',
          ['C2', 'C1'],
        ),
      ],
    );

    blocTest<BomBloc, BomState>(
      'BomUpdate_withFromDate_updatesComponentInPlace',
      setUp: () => when(
        () => restClient.updateBomItem(bomItem: wheel),
      ).thenAnswer((_) async => wheel),
      build: build,
      seed: () => BomState(bomItems: [frame, wheel]),
      act: (bloc) => bloc.add(BomUpdate(wheel)),
      expect: () => [
        bomState(BomStatus.success).having(
          (s) => s.bomItems.map((i) => i.toProductId),
          'components',
          ['C2', 'C1'],
        ),
      ],
    );

    blocTest<BomBloc, BomState>(
      'BomDelete_component_removesIt',
      setUp: () => when(
        () => restClient.deleteBomItem(bomItem: wheel),
      ).thenAnswer((_) async => wheel),
      build: build,
      seed: () => BomState(bomItems: [wheel, frame]),
      act: (bloc) => bloc.add(BomDelete(wheel)),
      expect: () => [
        bomState(BomStatus.success).having((s) => s.bomItems, 'items', [frame]),
      ],
    );
  });

  group('RoutingBloc', () {
    final routing = Routing(routingId: 'R1', routingName: 'Assembly');
    final task = RoutingTask(routingId: 'R1', taskName: 'Weld');

    TypeMatcher<RoutingState> routingState(
      RoutingStatus status, {
      List<Routing>? routings,
      String? message,
    }) {
      var m = isA<RoutingState>().having((s) => s.status, 'status', status);
      if (routings != null) {
        m = m.having((s) => s.routings, 'routings', routings);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    RoutingBloc build() => RoutingBloc(restClient);

    void stubList(List<Routing> list) => when(
      () => restClient.getRoutings(search: '', start: 0, limit: 20),
    ).thenAnswer((_) async => Routings(routings: list));

    blocTest<RoutingBloc, RoutingState>(
      'RoutingsFetch_initial_loadsFirstPage',
      setUp: () => stubList([routing]),
      build: build,
      act: (bloc) => bloc.add(const RoutingsFetch()),
      wait: fetchWait,
      expect: () => [
        routingState(RoutingStatus.loading),
        routingState(RoutingStatus.success, routings: [routing]),
      ],
    );

    blocTest<RoutingBloc, RoutingState>(
      'RoutingUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createRouting(routing: Routing(routingName: 'Paint')),
      ).thenAnswer((_) async => Routing(routingId: 'R2', routingName: 'Paint')),
      build: build,
      seed: () => RoutingState(routings: [routing]),
      act: (bloc) => bloc.add(RoutingUpdate(Routing(routingName: 'Paint'))),
      expect: () => [
        routingState(RoutingStatus.success).having(
          (s) => s.routings.map((r) => r.routingId),
          'ids',
          ['R2', 'R1'],
        ),
      ],
    );

    blocTest<RoutingBloc, RoutingState>(
      'RoutingDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteRouting(routing: routing),
      ).thenAnswer((_) async => routing),
      build: build,
      seed: () => RoutingState(routings: [routing]),
      act: (bloc) => bloc.add(RoutingDelete(routing)),
      expect: () => [routingState(RoutingStatus.success, routings: [])],
    );

    blocTest<RoutingBloc, RoutingState>(
      'RoutingTaskUpdate_newTask_createsAndRefreshesRoutings',
      setUp: () {
        when(
          () => restClient.createRoutingTask(routingTask: task),
        ).thenAnswer((_) async => task.copyWith(routingTaskId: 'T1'));
        stubList([
          routing.copyWith(routingTasks: [task]),
        ]);
      },
      build: build,
      seed: () =>
          RoutingState(status: RoutingStatus.success, routings: [routing]),
      act: (bloc) => bloc.add(RoutingTaskUpdate(task)),
      wait: fetchWait,
      verify: (bloc) =>
          expect(bloc.state.routings.single.routingTasks, hasLength(1)),
    );

    blocTest<RoutingBloc, RoutingState>(
      'RoutingTaskDelete_task_deletesAndRefreshes',
      setUp: () {
        when(
          () => restClient.deleteRoutingTask(
            routingTask: task.copyWith(routingTaskId: 'T1'),
          ),
        ).thenAnswer((_) async => task);
        stubList([routing]);
      },
      build: build,
      act: (bloc) =>
          bloc.add(RoutingTaskDelete(task.copyWith(routingTaskId: 'T1'))),
      wait: fetchWait,
      verify: (_) => verify(
        () => restClient.getRoutings(search: '', start: 0, limit: 20),
      ).called(1),
    );

    blocTest<RoutingBloc, RoutingState>(
      'RoutingTaskUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createRoutingTask(routingTask: task),
      ).thenThrow(dioError('Unknown routing')),
      build: build,
      act: (bloc) => bloc.add(RoutingTaskUpdate(task)),
      expect: () => [
        routingState(RoutingStatus.failure, message: 'Unknown routing'),
      ],
    );
  });
}
