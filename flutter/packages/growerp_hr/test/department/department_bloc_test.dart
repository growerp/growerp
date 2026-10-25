import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_hr/growerp_hr.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<DepartmentState> departmentState(
  DepartmentStatus status, {
  List<Department>? departments,
  String? message,
}) {
  var m = isA<DepartmentState>().having((s) => s.status, 'status', status);
  if (departments != null) {
    m = m.having((s) => s.departments, 'departments', departments);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final sales = Department(partyId: 'D1', name: 'Sales');
  final it = Department(partyId: 'D2', name: 'IT');

  setUp(() => restClient = MockRestClient());

  DepartmentBloc build() => DepartmentBloc(restClient);

  group('DepartmentsFetch', () {
    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentsFetch_refresh_loadsFirstPage',
      setUp: () => when(
        () => restClient.getDepartments(start: 0, limit: 20),
      ).thenAnswer((_) async => Departments(departments: [sales, it])),
      build: build,
      act: (bloc) => bloc.add(const DepartmentsFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(
          DepartmentStatus.success,
          departments: [sales, it],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentsFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.getDepartments(start: 1, limit: 20),
      ).thenAnswer((_) async => Departments(departments: [it])),
      build: build,
      seed: () => DepartmentState(departments: [sales]),
      act: (bloc) => bloc.add(const DepartmentsFetch()),
      wait: fetchWait,
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(DepartmentStatus.success, departments: [sales, it]),
      ],
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentsFetch_emptyNextPage_reachesMax',
      setUp: () => when(
        () => restClient.getDepartments(start: 1, limit: 20),
      ).thenAnswer((_) async => Departments()),
      build: build,
      seed: () => DepartmentState(departments: [sales]),
      act: (bloc) => bloc.add(const DepartmentsFetch()),
      wait: fetchWait,
      verify: (bloc) {
        expect(bloc.state.hasReachedMax, isTrue);
        expect(bloc.state.departments, [sales]);
      },
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentsFetch_reachedMaxSameSearch_doesNotFetch',
      build: build,
      seed: () => DepartmentState(departments: [sales], hasReachedMax: true),
      act: (bloc) => bloc.add(const DepartmentsFetch()),
      wait: fetchWait,
      expect: () => <DepartmentState>[],
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentsFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getDepartments(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const DepartmentsFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(DepartmentStatus.failure, message: 'No access'),
      ],
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentSearchChanged_threeChars_searchesFromStart',
      setUp: () => when(
        () => restClient.getDepartments(search: 'Sal', start: 0, limit: 20),
      ).thenAnswer((_) async => Departments(departments: [sales])),
      build: build,
      act: (bloc) =>
          bloc.add(const DepartmentSearchChanged(searchString: 'Sal')),
      wait: searchWait,
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(
          DepartmentStatus.success,
          departments: [sales],
        ).having((s) => s.searchString, 'searchString', 'Sal'),
      ],
    );
  });

  group('DepartmentUpdate / Delete', () {
    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createDepartment(department: Department(name: 'IT')),
      ).thenAnswer((_) async => it),
      build: build,
      seed: () => DepartmentState(departments: [sales]),
      act: (bloc) => bloc.add(DepartmentUpdate(Department(name: 'IT'))),
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(DepartmentStatus.success, departments: [it, sales]),
      ],
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () =>
            restClient.updateDepartment(department: it.copyWith(name: 'Tech')),
      ).thenAnswer((_) async => it.copyWith(name: 'Tech')),
      build: build,
      seed: () => DepartmentState(departments: [sales, it]),
      act: (bloc) => bloc.add(DepartmentUpdate(it.copyWith(name: 'Tech'))),
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(
          DepartmentStatus.success,
          departments: [
            sales,
            it.copyWith(name: 'Tech'),
          ],
        ),
      ],
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteDepartment(department: sales),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => DepartmentState(departments: [sales, it]),
      act: (bloc) => bloc.add(DepartmentDelete(sales)),
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(DepartmentStatus.success, departments: [it]),
      ],
    );

    blocTest<DepartmentBloc, DepartmentState>(
      'DepartmentDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteDepartment(department: sales),
      ).thenThrow(dioError('Has employees')),
      build: build,
      seed: () => DepartmentState(departments: [sales]),
      act: (bloc) => bloc.add(DepartmentDelete(sales)),
      expect: () => [
        departmentState(DepartmentStatus.loading),
        departmentState(DepartmentStatus.failure, message: 'Has employees'),
      ],
    );
  });
}
