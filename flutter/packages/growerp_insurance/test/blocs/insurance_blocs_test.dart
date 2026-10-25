import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_insurance/growerp_insurance.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// Fetch is throttled 100ms, SearchChanged debounced 300ms.
const fetchWait = Duration(milliseconds: 150);
const searchWait = Duration(milliseconds: 400);

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('PolicyBloc', () {
    final car = Policy(policyId: 'P1', policyNumber: 'CAR-1');
    final home = Policy(policyId: 'P2', policyNumber: 'HOME-1');

    TypeMatcher<PolicyState> policyState(
      PolicyStatusBloc status, {
      List<Policy>? policies,
      String? message,
    }) {
      var m = isA<PolicyState>().having((s) => s.status, 'status', status);
      if (policies != null) {
        m = m.having((s) => s.policies, 'policies', policies);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    PolicyBloc build() => PolicyBloc(restClient);

    blocTest<PolicyBloc, PolicyState>(
      'PoliciesFetch_expiringWithin30Days_sendsFilterAndLoads',
      setUp: () => when(
        () =>
            restClient.getPolicies(expiringWithinDays: 30, start: 0, limit: 20),
      ).thenAnswer((_) async => Policies(policies: [car])),
      build: build,
      act: (bloc) => bloc.add(const PoliciesFetch(expiringWithinDays: 30)),
      wait: fetchWait,
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(
          PolicyStatusBloc.success,
          policies: [car],
        ).having((s) => s.expiringWithinDays, 'expiring', 30),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PoliciesFetch_nextPage_appends',
      setUp: () => when(
        () => restClient.getPolicies(start: 1, limit: 20),
      ).thenAnswer((_) async => Policies(policies: [home])),
      build: build,
      seed: () => PolicyState(policies: [car]),
      act: (bloc) => bloc.add(const PoliciesFetch()),
      wait: fetchWait,
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(PolicyStatusBloc.success, policies: [car, home]),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PolicySearchChanged_threeChars_keepsExpiryFilter',
      setUp: () => when(
        () => restClient.getPolicies(
          expiringWithinDays: 30,
          search: 'CAR',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer((_) async => Policies(policies: [car])),
      build: build,
      seed: () => PolicyState(expiringWithinDays: 30, policies: [car, home]),
      act: (bloc) => bloc.add(const PolicySearchChanged(searchString: 'CAR')),
      wait: searchWait,
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(PolicyStatusBloc.success, policies: [car]),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PoliciesFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getPolicies(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const PoliciesFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(PolicyStatusBloc.failure, message: 'No access'),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PolicyUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createPolicy(policy: Policy(policyNumber: 'HOME-1')),
      ).thenAnswer((_) async => home),
      build: build,
      seed: () => PolicyState(policies: [car]),
      act: (bloc) => bloc.add(PolicyUpdate(Policy(policyNumber: 'HOME-1'))),
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(PolicyStatusBloc.success, policies: [home, car]),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PolicyUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updatePolicy(
          policy: car.copyWith(policyNumber: 'CAR-2'),
        ),
      ).thenAnswer((_) async => car.copyWith(policyNumber: 'CAR-2')),
      build: build,
      seed: () => PolicyState(policies: [car, home]),
      act: (bloc) =>
          bloc.add(PolicyUpdate(car.copyWith(policyNumber: 'CAR-2'))),
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(
          PolicyStatusBloc.success,
          policies: [
            car.copyWith(policyNumber: 'CAR-2'),
            home,
          ],
        ),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PolicyDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deletePolicy(policy: car),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => PolicyState(policies: [car, home]),
      act: (bloc) => bloc.add(PolicyDelete(car)),
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(PolicyStatusBloc.success, policies: [home]),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PolicyRenew_policy_refetchesWithCurrentFilterOneExtraRow',
      setUp: () {
        when(
          () => restClient.renewPolicy(policy: car),
        ).thenAnswer((_) async => home);
        when(
          () => restClient.getPolicies(
            expiringWithinDays: 30,
            start: 0,
            limit: 21,
          ),
        ).thenAnswer((_) async => Policies(policies: [home]));
      },
      build: build,
      seed: () => PolicyState(expiringWithinDays: 30, policies: [car]),
      act: (bloc) => bloc.add(PolicyRenew(car)),
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(
          PolicyStatusBloc.success,
          policies: [home],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PolicyCommissionReceive_amount_sendsStringAndReplacesPolicy',
      setUp: () => when(
        () =>
            restClient.receivePolicyCommission(policyId: 'P1', amount: '125.5'),
      ).thenAnswer((_) async => car.copyWith(policyNumber: 'CAR-1 paid')),
      build: build,
      seed: () => PolicyState(policies: [car]),
      act: (bloc) => bloc.add(
        PolicyCommissionReceive(
          policyId: 'P1',
          amount: Decimal.parse('125.50'),
        ),
      ),
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(PolicyStatusBloc.success).having(
          (s) => s.policies.single.policyNumber,
          'policyNumber',
          'CAR-1 paid',
        ),
      ],
    );

    blocTest<PolicyBloc, PolicyState>(
      'PolicyRenew_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.renewPolicy(policy: car),
      ).thenThrow(dioError('Not active')),
      build: build,
      act: (bloc) => bloc.add(PolicyRenew(car)),
      expect: () => [
        policyState(PolicyStatusBloc.loading),
        policyState(PolicyStatusBloc.failure, message: 'Not active'),
      ],
    );
  });

  group('ClaimBloc', () {
    final dent = Claim(claimId: 'CL1', policyId: 'P1');
    final flood = Claim(claimId: 'CL2', policyId: 'P2');

    TypeMatcher<ClaimState> claimState(
      ClaimStatusBloc status, {
      List<Claim>? claims,
      String? message,
    }) {
      var m = isA<ClaimState>().having((s) => s.status, 'status', status);
      if (claims != null) m = m.having((s) => s.claims, 'claims', claims);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    ClaimBloc build() => ClaimBloc(restClient);

    blocTest<ClaimBloc, ClaimState>(
      'ClaimsFetch_refresh_loadsFirstPage',
      setUp: () => when(
        () => restClient.getClaims(start: 0, limit: 20),
      ).thenAnswer((_) async => Claims(claims: [dent, flood])),
      build: build,
      act: (bloc) => bloc.add(const ClaimsFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        claimState(ClaimStatusBloc.loading),
        claimState(ClaimStatusBloc.success, claims: [dent, flood]),
      ],
    );

    blocTest<ClaimBloc, ClaimState>(
      'ClaimSearchChanged_threeChars_searchesFromStart',
      setUp: () => when(
        () => restClient.getClaims(search: 'flo', start: 0, limit: 20),
      ).thenAnswer((_) async => Claims(claims: [flood])),
      build: build,
      act: (bloc) => bloc.add(const ClaimSearchChanged(searchString: 'flo')),
      wait: searchWait,
      expect: () => [
        claimState(ClaimStatusBloc.loading),
        claimState(ClaimStatusBloc.success, claims: [flood]),
      ],
    );

    blocTest<ClaimBloc, ClaimState>(
      'ClaimsFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getClaims(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const ClaimsFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        claimState(ClaimStatusBloc.loading),
        claimState(ClaimStatusBloc.failure, message: 'No access'),
      ],
    );

    blocTest<ClaimBloc, ClaimState>(
      'ClaimUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createClaim(claim: Claim(policyId: 'P2')),
      ).thenAnswer((_) async => flood),
      build: build,
      seed: () => ClaimState(claims: [dent]),
      act: (bloc) => bloc.add(ClaimUpdate(Claim(policyId: 'P2'))),
      expect: () => [
        claimState(ClaimStatusBloc.loading),
        claimState(ClaimStatusBloc.success, claims: [flood, dent]),
      ],
    );

    blocTest<ClaimBloc, ClaimState>(
      'ClaimUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateClaim(claim: dent.copyWith(pseudoId: 'c1')),
      ).thenAnswer((_) async => dent.copyWith(pseudoId: 'c1')),
      build: build,
      seed: () => ClaimState(claims: [dent, flood]),
      act: (bloc) => bloc.add(ClaimUpdate(dent.copyWith(pseudoId: 'c1'))),
      expect: () => [
        claimState(ClaimStatusBloc.loading),
        claimState(
          ClaimStatusBloc.success,
          claims: [
            dent.copyWith(pseudoId: 'c1'),
            flood,
          ],
        ),
      ],
    );

    blocTest<ClaimBloc, ClaimState>(
      'ClaimDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteClaim(claim: dent),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => ClaimState(claims: [dent, flood]),
      act: (bloc) => bloc.add(ClaimDelete(dent)),
      expect: () => [
        claimState(ClaimStatusBloc.loading),
        claimState(ClaimStatusBloc.success, claims: [flood]),
      ],
    );
  });
}
