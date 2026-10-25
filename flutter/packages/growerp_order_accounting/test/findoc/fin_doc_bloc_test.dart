import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// FinDocFetch is throttled 100ms, FinDocSearchChanged debounced.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<FinDocState> finDocState(
  FinDocStatus status, {
  List<FinDoc>? finDocs,
  String? message,
}) {
  var m = isA<FinDocState>().having((s) => s.status, 'status', status);
  if (finDocs != null) m = m.having((s) => s.finDocs, 'finDocs', finDocs);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  setUp(() {
    restClient = MockRestClient();
    // module level caches shared by all FinDocBlocs
    saveItemTypes = [];
    savePaymentTypes = [];
  });

  FinDocBloc orderBloc() =>
      FinDocBloc(restClient, true, FinDocType.order, applicationId);

  void stubGetFinDoc({
    FinDocType docType = FinDocType.order,
    bool? sales = true,
    int start = 0,
    String searchString = '',
    String? journalId,
    required Future<FinDocs> Function(Invocation) answer,
  }) => when(
    () => restClient.getFinDoc(
      start: start,
      limit: 20,
      sales: sales,
      docType: docType,
      searchString: searchString,
      journalId: journalId,
      my: false,
    ),
  ).thenAnswer(answer);

  group('FinDocFetch', () {
    blocTest<FinDocBloc, FinDocState>(
      'FinDocFetch_initialOrders_loadsItemTypesAndFirstPage',
      setUp: () {
        when(
          () => restClient.getItemTypes(sales: true),
        ).thenAnswer((_) async => ItemTypes(itemTypes: [itemType1]));
        stubGetFinDoc(answer: (_) async => FinDocs(finDocs: [order1, order2]));
      },
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocFetch()),
      wait: fetchWait,
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.success, finDocs: [order1, order2])
            .having((s) => s.itemTypes, 'itemTypes', [itemType1])
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocFetch_payments_loadsPaymentTypesNotItemTypes',
      setUp: () {
        when(
          () => restClient.getPaymentTypes(sales: false),
        ).thenAnswer((_) async => PaymentTypes(paymentTypes: [paymentType1]));
        stubGetFinDoc(
          docType: FinDocType.payment,
          sales: false,
          answer: (_) async => FinDocs(finDocs: [payment1]),
        );
      },
      build: () =>
          FinDocBloc(restClient, false, FinDocType.payment, applicationId),
      act: (bloc) => bloc.add(const FinDocFetch()),
      wait: fetchWait,
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          finDocs: [payment1],
        ).having((s) => s.paymentTypes, 'paymentTypes', [paymentType1]),
      ],
      verify: (_) => verifyNever(
        () => restClient.getItemTypes(sales: any(named: 'sales')),
      ),
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocFetch_transactions_sendsNoSalesFilter',
      setUp: () {
        when(
          () => restClient.getItemTypes(sales: true),
        ).thenAnswer((_) async => ItemTypes());
        stubGetFinDoc(
          docType: FinDocType.transaction,
          sales: null,
          journalId: 'J1',
          answer: (_) async => FinDocs(),
        );
      },
      build: () =>
          FinDocBloc(restClient, true, FinDocType.transaction, applicationId),
      act: (bloc) => bloc.add(const FinDocFetch(journalId: 'J1')),
      wait: fetchWait,
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.success, finDocs: []),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocFetch_nextPage_appendsFromCurrentLength',
      setUp: () => stubGetFinDoc(
        start: 1,
        answer: (_) async => FinDocs(finDocs: [order2]),
      ),
      build: orderBloc,
      seed: () => FinDocState(
        status: FinDocStatus.success,
        finDocs: [order1],
        itemTypes: [itemType1],
      ),
      act: (bloc) => bloc.add(const FinDocFetch()),
      wait: fetchWait,
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.success, finDocs: [order1, order2]),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocFetch_restThrowsDio_emitsFailureAndKeepsList',
      setUp: () => stubGetFinDoc(
        start: 1,
        answer: (_) async => throw dioError('Order service down'),
      ),
      build: orderBloc,
      seed: () => FinDocState(
        status: FinDocStatus.success,
        finDocs: [order1],
        itemTypes: [itemType1],
      ),
      act: (bloc) => bloc.add(const FinDocFetch()),
      wait: fetchWait,
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.failure,
          finDocs: [order1],
          message: 'Order service down',
        ),
      ],
    );
  });

  group('FinDocSearchChanged', () {
    blocTest<FinDocBloc, FinDocState>(
      'FinDocSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => stubGetFinDoc(
        searchString: 'ord',
        answer: (_) async => FinDocs(finDocs: [order1]),
      ),
      build: orderBloc,
      seed: () => FinDocState(
        status: FinDocStatus.success,
        finDocs: [order1, order2],
        itemTypes: [itemType1],
      ),
      act: (bloc) => bloc.add(const FinDocSearchChanged(searchString: 'ord')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.success, finDocs: [order1]),
      ],
    );
  });

  group('FinDocUpdate', () {
    final item1 = FinDocItem(itemSeqId: '01', description: 'first');
    final item2 = FinDocItem(itemSeqId: '02', description: 'second');

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdate_newOrder_sortsItemsAddsStoreAndInsertsFirst',
      setUp: () => when(
        () => restClient.createFinDoc(
          finDoc: FinDoc(
            docType: FinDocType.order,
            applicationId: applicationId,
            items: [item1, item2],
          ),
        ),
      ).thenAnswer((_) async => order2),
      build: orderBloc,
      seed: () => FinDocState(status: FinDocStatus.success, finDocs: [order1]),
      act: (bloc) => bloc.add(
        FinDocUpdate(FinDoc(docType: FinDocType.order, items: [item2, item1])),
      ),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          finDocs: [order2, order1],
          message: 'finDocAddSuccess:Order:order2',
        ),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdate_existingOrder_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateFinDoc(
          finDoc: order2.copyWith(applicationId: applicationId),
        ),
      ).thenAnswer((_) async => order2.copyWith(description: 'changed')),
      build: orderBloc,
      seed: () =>
          FinDocState(status: FinDocStatus.success, finDocs: [order1, order2]),
      act: (bloc) => bloc.add(FinDocUpdate(order2)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          finDocs: [
            order1,
            order2.copyWith(description: 'changed'),
          ],
          message: 'finDocUpdateSuccess',
        ),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdate_cancelTransaction_removesItFromList',
      setUp: () {
        final cancelled = FinDoc(
          docType: FinDocType.transaction,
          transactionId: 'T1',
          status: FinDocStatusVal.cancelled,
        );
        when(
          () => restClient.updateFinDoc(
            finDoc: cancelled.copyWith(applicationId: applicationId),
          ),
        ).thenAnswer((_) async => cancelled);
      },
      build: () =>
          FinDocBloc(restClient, true, FinDocType.transaction, applicationId),
      seed: () => FinDocState(
        status: FinDocStatus.success,
        finDocs: [FinDoc(docType: FinDocType.transaction, transactionId: 'T1')],
      ),
      act: (bloc) => bloc.add(
        FinDocUpdate(
          FinDoc(
            docType: FinDocType.transaction,
            transactionId: 'T1',
            status: FinDocStatusVal.cancelled,
          ),
        ),
      ),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          finDocs: [],
          message: 'finDocDeleteSuccess',
        ),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateFinDoc(
          finDoc: order1.copyWith(applicationId: applicationId),
        ),
      ).thenThrow(dioError('Order already approved')),
      build: orderBloc,
      seed: () => FinDocState(status: FinDocStatus.success, finDocs: [order1]),
      act: (bloc) => bloc.add(FinDocUpdate(order1)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'Order already approved'),
      ],
    );
  });

  group('FinDocShipmentReceive', () {
    final shipment = FinDoc(docType: FinDocType.shipment, shipmentId: 'S1');
    final received = shipment.copyWith(status: FinDocStatusVal.completed);

    blocTest<FinDocBloc, FinDocState>(
      'FinDocShipmentReceive_success_replacesShipment',
      setUp: () => when(
        () => restClient.receiveShipment(finDoc: shipment),
      ).thenAnswer((_) async => received),
      build: () =>
          FinDocBloc(restClient, false, FinDocType.shipment, applicationId),
      seed: () =>
          FinDocState(status: FinDocStatus.success, finDocs: [shipment]),
      act: (bloc) => bloc.add(FinDocShipmentReceive(shipment)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.success, finDocs: [received]),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocShipmentReceive_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.receiveShipment(finDoc: shipment),
      ).thenThrow(dioError('Location missing')),
      build: () =>
          FinDocBloc(restClient, false, FinDocType.shipment, applicationId),
      seed: () =>
          FinDocState(status: FinDocStatus.success, finDocs: [shipment]),
      act: (bloc) => bloc.add(FinDocShipmentReceive(shipment)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'Location missing'),
      ],
    );
  });

  group('FinDocGetItemTypes', () {
    blocTest<FinDocBloc, FinDocState>(
      'FinDocGetItemTypes_noSearch_loadsFromBackend',
      setUp: () => when(
        () => restClient.getItemTypes(sales: true),
      ).thenAnswer((_) async => ItemTypes(itemTypes: [itemType1, itemType2])),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGetItemTypes(sales: true)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
        ).having((s) => s.itemTypes, 'itemTypes', [itemType1, itemType2]),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGetItemTypes_search_filtersCachedByNameOrAccount',
      setUp: () => saveItemTypes = [itemType1, itemType2],
      build: orderBloc,
      act: (bloc) => bloc
        ..add(const FinDocGetItemTypes(searchString: 'SHIP'))
        ..add(const FinDocGetItemTypes(searchString: '400')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
        ).having((s) => s.itemTypes, 'itemTypes', [itemType2]),
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
        ).having((s) => s.itemTypes, 'itemTypes', [itemType1]),
      ],
      verify: (_) => verifyZeroInteractions(restClient),
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGetItemTypes_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getItemTypes(sales: true),
      ).thenThrow(dioError('No access')),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGetItemTypes(sales: true)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'No access'),
      ],
    );
  });

  group('FinDocUpdateItemType', () {
    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdateItemType_update_setsAccountInStateAndCache',
      setUp: () {
        saveItemTypes = [itemType2];
        when(
          () => restClient.updateItemType(itemType: itemType2, update: true),
        ).thenAnswer(
          (_) async =>
              itemType2.copyWith(accountCode: '4100', accountName: 'Freight'),
        );
      },
      build: orderBloc,
      seed: () =>
          FinDocState(status: FinDocStatus.success, itemTypes: [itemType2]),
      act: (bloc) =>
          bloc.add(FinDocUpdateItemType(itemType: itemType2, update: true)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          message: 'Item Type: Shipping updated',
        ).having((s) => s.itemTypes.single.accountCode, 'accountCode', '4100'),
      ],
      verify: (_) => expect(saveItemTypes.single.accountName, 'Freight'),
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdateItemType_delete_clearsAccount',
      setUp: () {
        saveItemTypes = [itemType1];
        when(
          () => restClient.updateItemType(itemType: itemType1, delete: true),
        ).thenAnswer((_) async => itemType1);
      },
      build: orderBloc,
      seed: () =>
          FinDocState(status: FinDocStatus.success, itemTypes: [itemType1]),
      act: (bloc) =>
          bloc.add(FinDocUpdateItemType(itemType: itemType1, delete: true)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          message: 'Item Type: Product removed',
        ).having((s) => s.itemTypes.single.accountCode, 'accountCode', ''),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdateItemType_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateItemType(itemType: itemType1, update: true),
      ).thenThrow(dioError('Unknown account')),
      build: orderBloc,
      act: (bloc) =>
          bloc.add(FinDocUpdateItemType(itemType: itemType1, update: true)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'Unknown account'),
      ],
    );
  });

  group('FinDocGetPaymentTypes', () {
    final payable = PaymentType(
      paymentTypeId: 'PtVendor',
      isPayable: true,
      paymentTypeName: 'Vendor payment',
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGetPaymentTypes_noSearch_loadsFromBackend',
      setUp: () =>
          when(() => restClient.getPaymentTypes(sales: false)).thenAnswer(
            (_) async => PaymentTypes(paymentTypes: [paymentType1, payable]),
          ),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGetPaymentTypes(sales: false)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.success).having(
          (s) => s.paymentTypes,
          'paymentTypes',
          [paymentType1, payable],
        ),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGetPaymentTypes_searchOutgoing_filtersOnDirection',
      setUp: () => savePaymentTypes = [paymentType1, payable],
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGetPaymentTypes(searchString: 'out')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
        ).having((s) => s.paymentTypes, 'paymentTypes', [payable]),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGetPaymentTypes_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getPaymentTypes(sales: false),
      ).thenThrow(dioError('No access')),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGetPaymentTypes(sales: false)),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'No access'),
      ],
    );
  });

  group('FinDocUpdatePaymentType', () {
    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdatePaymentType_update_setsAccountInStateAndCache',
      setUp: () {
        savePaymentTypes = [paymentType1];
        when(
          () => restClient.updatePaymentType(
            paymentType: paymentType1,
            update: true,
          ),
        ).thenAnswer(
          (_) async =>
              paymentType1.copyWith(accountCode: '1010', accountName: 'Bank'),
        );
      },
      build: orderBloc,
      seed: () => FinDocState(
        status: FinDocStatus.success,
        paymentTypes: [paymentType1],
      ),
      act: (bloc) => bloc.add(
        FinDocUpdatePaymentType(paymentType: paymentType1, update: true),
      ),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          message: 'Payment Type: Cash updated',
        ).having(
          (s) => s.paymentTypes.single.accountCode,
          'accountCode',
          '1010',
        ),
      ],
      verify: (_) => expect(savePaymentTypes.single.accountName, 'Bank'),
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdatePaymentType_delete_clearsAccount',
      setUp: () {
        savePaymentTypes = [paymentType1];
        when(
          () => restClient.updatePaymentType(
            paymentType: paymentType1,
            delete: true,
          ),
        ).thenAnswer((_) async => paymentType1);
      },
      build: orderBloc,
      seed: () => FinDocState(
        status: FinDocStatus.success,
        paymentTypes: [paymentType1],
      ),
      act: (bloc) => bloc.add(
        FinDocUpdatePaymentType(paymentType: paymentType1, delete: true),
      ),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          message: 'Payment Type: Cash removed',
        ).having((s) => s.paymentTypes.single.accountCode, 'accountCode', ''),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocUpdatePaymentType_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updatePaymentType(
          paymentType: paymentType1,
          update: true,
        ),
      ).thenThrow(dioError('Unknown account')),
      build: orderBloc,
      act: (bloc) => bloc.add(
        FinDocUpdatePaymentType(paymentType: paymentType1, update: true),
      ),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'Unknown account'),
      ],
    );
  });

  group('FinDocProductRentalDates', () {
    final dates = ProductRentalDate(
      productId: 'R1',
      dates: [DateTime.utc(2026, 11, 1)],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocProductRentalDates_success_setsOccupancy',
      setUp: () =>
          when(
            () => restClient.getDailyRentalOccupancy(productId: 'R1'),
          ).thenAnswer(
            (_) async => ProductRentalDates(productRentalDates: [dates]),
          ),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocProductRentalDates('R1')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
        ).having((s) => s.productRentalDates, 'productRentalDates', [dates]),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocProductRentalDates_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getDailyRentalOccupancy(productId: 'R1'),
      ).thenThrow(dioError('Unknown product')),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocProductRentalDates('R1')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'Unknown product'),
      ],
    );
  });

  group('FinDocGatewayPayment', () {
    final gatewayPayment = payment1.copyWith(
      grandTotal: Decimal.parse('12.50'),
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGatewayPaymentAuthorize_success_setsPaymentAndMessage',
      setUp: () => when(
        () => restClient.authorizeGatewayPayment(paymentId: 'P1'),
      ).thenAnswer((_) async => gatewayPayment),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGatewayPaymentAuthorize('P1')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          message: 'Payment pay1 12.5 authorized for payment',
        ).having((s) => s.finDoc, 'finDoc', gatewayPayment),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGatewayPaymentCapture_success_setsPaymentAndMessage',
      setUp: () => when(
        () => restClient.captureGatewayPayment(paymentId: 'P1'),
      ).thenAnswer((_) async => gatewayPayment),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGatewayPaymentCapture('P1')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          message: 'Payment pay1 12.5 captured for payment',
        ),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGatewayPaymentRelease_success_emitsRefundMessage',
      setUp: () => when(
        () => restClient.releaseGatewayPayment(paymentId: 'P1'),
      ).thenAnswer((_) async => gatewayPayment),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGatewayPaymentRelease('P1')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(
          FinDocStatus.success,
          message: 'paymentRefundSuccess:pay1:12.5',
        ),
      ],
    );

    blocTest<FinDocBloc, FinDocState>(
      'FinDocGatewayPaymentCapture_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.captureGatewayPayment(paymentId: 'P1'),
      ).thenThrow(dioError('Card declined')),
      build: orderBloc,
      act: (bloc) => bloc.add(const FinDocGatewayPaymentCapture('P1')),
      expect: () => [
        finDocState(FinDocStatus.loading),
        finDocState(FinDocStatus.failure, message: 'Card declined'),
      ],
    );
  });

  group('FinDocReset', () {
    blocTest<FinDocBloc, FinDocState>(
      'FinDocReset_logout_returnsToInitialState',
      build: () {
        final authBloc = MockAuthBloc();
        whenListen(
          authBloc,
          Stream.value(const AuthState(status: AuthStatus.unAuthenticated)),
          initialState: const AuthState(status: AuthStatus.authenticated),
        );
        return FinDocBloc(
          restClient,
          true,
          FinDocType.order,
          applicationId,
          authBloc: authBloc,
        );
      },
      seed: () => FinDocState(status: FinDocStatus.success, finDocs: [order1]),
      expect: () => [const FinDocState()],
    );
  });
}
