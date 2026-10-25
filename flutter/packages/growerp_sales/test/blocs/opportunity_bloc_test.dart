import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// OpportunityFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<OpportunityState> oppState(
  OpportunityStatus status, {
  List<Opportunity>? opportunities,
  String? message,
}) {
  var m = isA<OpportunityState>().having((s) => s.status, 'status', status);
  if (opportunities != null) {
    m = m.having((s) => s.opportunities, 'opportunities', opportunities);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final erp = Opportunity(opportunityId: 'O1', opportunityName: 'ERP');
  final crm = Opportunity(opportunityId: 'O2', opportunityName: 'CRM');

  setUpAll(() => registerFallbackValue(FinDoc()));
  setUp(() => restClient = MockRestClient());

  OpportunityBloc build() => OpportunityBloc(restClient);

  group('OpportunityFetch', () {
    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityFetch_initial_loadsFirstPage',
      setUp: () => when(
        () => restClient.getOpportunity(start: 0, searchString: '', limit: 20),
      ).thenAnswer((_) async => Opportunities(opportunities: [erp, crm])),
      build: build,
      act: (bloc) => bloc.add(const OpportunityFetch()),
      wait: fetchWait,
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(OpportunityStatus.success, opportunities: [erp, crm]),
      ],
    );

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityFetch_searchWithoutRefresh_fillsSearchResultsOnly',
      setUp: () => when(
        () =>
            restClient.getOpportunity(start: 0, searchString: 'ER', limit: 20),
      ).thenAnswer((_) async => Opportunities(opportunities: [erp])),
      build: build,
      seed: () => OpportunityState(
        status: OpportunityStatus.success,
        opportunities: [erp, crm],
      ),
      act: (bloc) => bloc.add(const OpportunityFetch(searchString: 'ER')),
      wait: fetchWait,
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(
          OpportunityStatus.success,
          opportunities: [erp, crm],
        ).having((s) => s.searchResults, 'searchResults', [erp]),
      ],
    );

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunitySearchChanged_threeChars_refreshesListWithSearch',
      setUp: () => when(
        () =>
            restClient.getOpportunity(start: 0, searchString: 'ERP', limit: 20),
      ).thenAnswer((_) async => Opportunities(opportunities: [erp])),
      build: build,
      act: (bloc) =>
          bloc.add(const OpportunitySearchChanged(searchString: 'ERP')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(OpportunityStatus.success, opportunities: [erp]),
      ],
    );

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getOpportunity(start: 0, searchString: '', limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const OpportunityFetch()),
      wait: fetchWait,
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(OpportunityStatus.failure, message: 'No access'),
      ],
    );
  });

  blocTest<OpportunityBloc, OpportunityState>(
    'OpportunitySummaryFetch_any_usesOwnStatusSoDialogsStayOpen',
    setUp: () => when(() => restClient.getOpportunitySummary()).thenAnswer(
      (_) async => OpportunitySummary(
        stageSummary: [OpportunitySummaryItem(stageId: 'Quote')],
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const OpportunitySummaryFetch()),
    expect: () => [
      oppState(
        OpportunityStatus.summarySuccess,
      ).having((s) => s.summary.single.stageId, 'stage', 'Quote'),
    ],
  );

  group('OpportunityUpdate / Delete', () {
    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createOpportunity(
          opportunity: Opportunity(opportunityName: 'CRM'),
        ),
      ).thenAnswer((_) async => crm),
      build: build,
      seed: () => OpportunityState(opportunities: [erp]),
      act: (bloc) =>
          bloc.add(OpportunityUpdate(Opportunity(opportunityName: 'CRM'))),
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(
          OpportunityStatus.success,
          opportunities: [crm, erp],
          message: 'opportunityAddSuccess:CRM',
        ),
      ],
    );

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateOpportunity(
          opportunity: crm.copyWith(stageId: 'Proposal'),
        ),
      ).thenAnswer((_) async => crm.copyWith(stageId: 'Proposal')),
      build: build,
      seed: () => OpportunityState(opportunities: [erp, crm]),
      act: (bloc) =>
          bloc.add(OpportunityUpdate(crm.copyWith(stageId: 'Proposal'))),
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(
          OpportunityStatus.success,
          opportunities: [
            erp,
            crm.copyWith(stageId: 'Proposal'),
          ],
        ),
      ],
    );

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteOpportunity(opportunity: erp),
      ).thenAnswer((_) async => erp),
      build: build,
      seed: () => OpportunityState(opportunities: [erp, crm]),
      act: (bloc) => bloc.add(OpportunityDelete(erp)),
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(
          OpportunityStatus.success,
          opportunities: [crm],
          message: 'opportunityDeleteSuccess:ERP',
        ),
      ],
    );

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteOpportunity(opportunity: erp),
      ).thenThrow(dioError('Has orders')),
      build: build,
      seed: () => OpportunityState(opportunities: [erp]),
      act: (bloc) => bloc.add(OpportunityDelete(erp)),
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(OpportunityStatus.failure, message: 'Has orders'),
      ],
    );
  });

  group('OpportunityConvertToOrder', () {
    final lead = User(
      partyId: 'L1',
      company: Company(partyId: 'C1'),
    );
    final deal = erp.copyWith(leadUser: lead, estAmount: Decimal.parse('900'));

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityConvertToOrder_deal_createsQuoteAndMovesToQuoteStage',
      setUp: () {
        when(
          () => restClient.createFinDoc(finDoc: any(named: 'finDoc')),
        ).thenAnswer(
          (_) async => FinDoc(
            docType: FinDocType.order,
            orderId: 'SO1',
            pseudoId: 'so1',
          ),
        );
        when(
          () => restClient.updateOpportunity(
            opportunity: deal.copyWith(stageId: 'Quote'),
          ),
        ).thenAnswer((_) async => deal.copyWith(stageId: 'Quote'));
      },
      build: build,
      seed: () => OpportunityState(opportunities: [deal, crm]),
      act: (bloc) => bloc.add(OpportunityConvertToOrder(deal)),
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(
              OpportunityStatus.success,
              message: 'opportunityConvertSuccess:so1',
            )
            .having((s) => s.convertedOrderId, 'orderId', 'SO1')
            .having((s) => s.opportunities.first.stageId, 'stage', 'Quote'),
      ],
      verify: (_) {
        final quote =
            verify(
                  () => restClient.createFinDoc(
                    finDoc: captureAny(named: 'finDoc'),
                  ),
                ).captured.single
                as FinDoc;
        expect(quote.sales, isTrue);
        expect(quote.status, FinDocStatusVal.inPreparation);
        expect(quote.grandTotal, Decimal.parse('900'));
        expect(quote.otherCompany?.partyId, 'C1');
      },
    );

    blocTest<OpportunityBloc, OpportunityState>(
      'OpportunityConvertToOrder_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createFinDoc(finDoc: any(named: 'finDoc')),
      ).thenThrow(dioError('No product store')),
      build: build,
      act: (bloc) => bloc.add(OpportunityConvertToOrder(deal)),
      expect: () => [
        oppState(OpportunityStatus.loading),
        oppState(OpportunityStatus.failure, message: 'No product store'),
      ],
    );
  });
}
