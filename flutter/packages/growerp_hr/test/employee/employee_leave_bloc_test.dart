import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_hr/growerp_hr.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('EmployeeBloc', () {
    final jane = Employee(partyId: 'E1', firstName: 'Jane', lastName: 'Roe');
    final max = Employee(partyId: 'E2', firstName: 'Max', lastName: 'Power');

    TypeMatcher<EmployeeState> employeeState(
      EmployeeStatusBloc status, {
      List<Employee>? employees,
      String? message,
    }) {
      var m = isA<EmployeeState>().having((s) => s.status, 'status', status);
      if (employees != null) {
        m = m.having((s) => s.employees, 'employees', employees);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    EmployeeBloc build() => EmployeeBloc(restClient);

    blocTest<EmployeeBloc, EmployeeState>(
      'EmployeesFetch_ownRecord_requestsByPartyId',
      setUp: () => when(
        () => restClient.getEmployees(partyId: 'E1', start: 0, limit: 20),
      ).thenAnswer((_) async => Employees(employees: [jane])),
      build: build,
      act: (bloc) =>
          bloc.add(const EmployeesFetch(refresh: true, partyId: 'E1')),
      wait: fetchWait,
      expect: () => [
        employeeState(EmployeeStatusBloc.loading),
        employeeState(EmployeeStatusBloc.success, employees: [jane]),
      ],
    );

    blocTest<EmployeeBloc, EmployeeState>(
      'EmployeeSearchChanged_threeChars_searchesFromStart',
      setUp: () => when(
        () => restClient.getEmployees(search: 'Max', start: 0, limit: 20),
      ).thenAnswer((_) async => Employees(employees: [max])),
      build: build,
      act: (bloc) => bloc.add(const EmployeeSearchChanged(searchString: 'Max')),
      wait: searchWait,
      expect: () => [
        employeeState(EmployeeStatusBloc.loading),
        employeeState(EmployeeStatusBloc.success, employees: [max]),
      ],
    );

    blocTest<EmployeeBloc, EmployeeState>(
      'EmployeesFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getEmployees(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const EmployeesFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        employeeState(EmployeeStatusBloc.loading),
        employeeState(EmployeeStatusBloc.failure, message: 'No access'),
      ],
    );

    blocTest<EmployeeBloc, EmployeeState>(
      'EmployeeUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createEmployee(employee: Employee(firstName: 'Max')),
      ).thenAnswer((_) async => max),
      build: build,
      seed: () => EmployeeState(employees: [jane]),
      act: (bloc) => bloc.add(EmployeeUpdate(Employee(firstName: 'Max'))),
      expect: () => [
        employeeState(EmployeeStatusBloc.loading),
        employeeState(EmployeeStatusBloc.success, employees: [max, jane]),
      ],
    );

    blocTest<EmployeeBloc, EmployeeState>(
      'EmployeeUpdate_existing_replacesIt',
      setUp: () => when(
        () =>
            restClient.updateEmployee(employee: jane.copyWith(lastName: 'Doe')),
      ).thenAnswer((_) async => jane.copyWith(lastName: 'Doe')),
      build: build,
      seed: () => EmployeeState(employees: [jane, max]),
      act: (bloc) => bloc.add(EmployeeUpdate(jane.copyWith(lastName: 'Doe'))),
      expect: () => [
        employeeState(EmployeeStatusBloc.loading),
        employeeState(
          EmployeeStatusBloc.success,
          employees: [
            jane.copyWith(lastName: 'Doe'),
            max,
          ],
        ),
      ],
    );

    blocTest<EmployeeBloc, EmployeeState>(
      'EmployeeOnboardingTaskUpdate_done_usesChecklistStatusSoDialogStaysOpen',
      setUp: () => when(
        () => restClient.updateEmployeeOnboardingTask(
          partyId: 'E1',
          onboardingTaskId: 'T1',
          completed: true,
        ),
      ).thenAnswer((_) async => jane.copyWith(email: 'jane@x.com')),
      build: build,
      seed: () => EmployeeState(employees: [jane]),
      act: (bloc) => bloc.add(
        const EmployeeOnboardingTaskUpdate(
          partyId: 'E1',
          onboardingTaskId: 'T1',
          completed: true,
        ),
      ),
      expect: () => [
        employeeState(EmployeeStatusBloc.loading),
        employeeState(
          EmployeeStatusBloc.checklistSuccess,
          employees: [jane.copyWith(email: 'jane@x.com')],
        ),
      ],
    );

    blocTest<EmployeeBloc, EmployeeState>(
      'EmployeeUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateEmployee(employee: jane),
      ).thenThrow(dioError('Email taken')),
      build: build,
      act: (bloc) => bloc.add(EmployeeUpdate(jane)),
      expect: () => [
        employeeState(EmployeeStatusBloc.loading),
        employeeState(EmployeeStatusBloc.failure, message: 'Email taken'),
      ],
    );
  });

  group('LeaveRequestBloc', () {
    final holiday = LeaveRequest(leaveRequestId: 'LR1', partyId: 'E1');
    final sick = LeaveRequest(leaveRequestId: 'LR2', partyId: 'E1');
    final annual = LeaveBalance(partyId: 'E1', leaveType: LeaveType.annual);

    TypeMatcher<LeaveRequestState> leaveState(
      LeaveRequestStatus status, {
      List<LeaveRequest>? requests,
      String? message,
    }) {
      var m = isA<LeaveRequestState>().having(
        (s) => s.status,
        'status',
        status,
      );
      if (requests != null) {
        m = m.having((s) => s.leaveRequests, 'leaveRequests', requests);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    LeaveRequestBloc build() => LeaveRequestBloc(restClient);

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveRequestsFetch_pendingForEmployee_sendsStatusAndParty',
      setUp: () => when(
        () => restClient.getLeaveRequests(
          partyId: 'E1',
          statusId: 'HrlsPending',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer((_) async => LeaveRequests(leaveRequests: [holiday])),
      build: build,
      act: (bloc) => bloc.add(
        const LeaveRequestsFetch(
          refresh: true,
          partyId: 'E1',
          leaveStatus: LeaveStatus.pending,
        ),
      ),
      wait: fetchWait,
      expect: () => [
        leaveState(LeaveRequestStatus.loading),
        leaveState(LeaveRequestStatus.success, requests: [holiday]),
      ],
    );

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveRequestsFetch_nextPage_appends',
      setUp: () => when(
        () => restClient.getLeaveRequests(start: 1, limit: 20),
      ).thenAnswer((_) async => LeaveRequests(leaveRequests: [sick])),
      build: build,
      seed: () => LeaveRequestState(leaveRequests: [holiday]),
      act: (bloc) => bloc.add(const LeaveRequestsFetch()),
      wait: fetchWait,
      expect: () => [
        leaveState(LeaveRequestStatus.loading),
        leaveState(LeaveRequestStatus.success, requests: [holiday, sick]),
      ],
    );

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveRequestsFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getLeaveRequests(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const LeaveRequestsFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        leaveState(LeaveRequestStatus.loading),
        leaveState(LeaveRequestStatus.failure, message: 'No access'),
      ],
    );

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveRequestUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createLeaveRequest(
          leaveRequest: LeaveRequest(partyId: 'E1'),
        ),
      ).thenAnswer((_) async => sick),
      build: build,
      seed: () => LeaveRequestState(leaveRequests: [holiday]),
      act: (bloc) => bloc.add(LeaveRequestUpdate(LeaveRequest(partyId: 'E1'))),
      expect: () => [
        leaveState(LeaveRequestStatus.loading),
        leaveState(LeaveRequestStatus.success, requests: [sick, holiday]),
      ],
    );

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveRequestDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteLeaveRequest(leaveRequest: holiday),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => LeaveRequestState(leaveRequests: [holiday, sick]),
      act: (bloc) => bloc.add(LeaveRequestDelete(holiday)),
      expect: () => [
        leaveState(LeaveRequestStatus.loading),
        leaveState(LeaveRequestStatus.success, requests: [sick]),
      ],
    );

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveBalancesFetch_year_usesOwnStatusSoDialogStaysOpen',
      setUp: () => when(
        () => restClient.getLeaveAllowances(partyId: 'E1', year: 2026),
      ).thenAnswer((_) async => LeaveBalances(leaveBalances: [annual])),
      build: build,
      act: (bloc) =>
          bloc.add(const LeaveBalancesFetch(partyId: 'E1', year: 2026)),
      expect: () => [
        leaveState(
          LeaveRequestStatus.balancesSuccess,
        ).having((s) => s.balances, 'balances', [annual]),
      ],
    );

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveAllowanceUpdate_days_sendsEnumValueAndDaysAsString',
      setUp: () => when(
        () => restClient.updateLeaveAllowance(
          partyId: 'E1',
          leaveTypeEnumId: 'HrltAnnual',
          year: 2026,
          days: '25',
        ),
      ).thenAnswer((_) async => LeaveBalances(leaveBalances: [annual])),
      build: build,
      act: (bloc) => bloc.add(
        LeaveAllowanceUpdate(
          partyId: 'E1',
          leaveType: LeaveType.annual,
          year: 2026,
          days: Decimal.parse('25'),
        ),
      ),
      expect: () => [leaveState(LeaveRequestStatus.balancesSuccess)],
    );

    blocTest<LeaveRequestBloc, LeaveRequestState>(
      'LeaveBalancesFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getLeaveAllowances(partyId: 'E1', year: 2026),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) =>
          bloc.add(const LeaveBalancesFetch(partyId: 'E1', year: 2026)),
      expect: () => [
        leaveState(LeaveRequestStatus.failure, message: 'No access'),
      ],
    );
  });
}
