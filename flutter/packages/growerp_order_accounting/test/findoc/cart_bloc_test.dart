import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/mocks.dart';

TypeMatcher<CartState> cartState(CartStatus status, {FinDoc? finDoc}) {
  var m = isA<CartState>().having((s) => s.status, 'status', status);
  if (finDoc != null) m = m.having((s) => s.finDoc, 'finDoc', finDoc);
  return m;
}

FinDocItem item(String description, String price, String quantity) =>
    FinDocItem(
      description: description,
      price: Decimal.parse(price),
      quantity: Decimal.parse(quantity),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockRestClient restClient;
  late MockFinDocBloc finDocBloc;

  final emptyCart = FinDoc(sales: true, docType: FinDocType.order, items: []);

  setUpAll(() => registerFallbackValue(const FinDocReset()));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    restClient = MockRestClient();
    finDocBloc = MockFinDocBloc();
  });

  CartBloc build() => CartBloc(
    restClient: restClient,
    sales: true,
    docType: FinDocType.order,
    finDocBloc: finDocBloc,
  );

  group('CartFetch', () {
    blocTest<CartBloc, CartState>(
      'CartFetch_initialNoSavedCart_loadsItemTypesAndUsesGivenDoc',
      setUp: () => when(
        () => restClient.getItemTypes(sales: true),
      ).thenAnswer((_) async => ItemTypes(itemTypes: [itemType1])),
      build: build,
      act: (bloc) => bloc.add(CartFetch(emptyCart)),
      expect: () => [
        cartState(
          CartStatus.inProcess,
          finDoc: emptyCart,
        ).having((s) => s.itemTypes, 'itemTypes', [itemType1]),
      ],
    );

    blocTest<CartBloc, CartState>(
      'CartFetch_notInitial_doesNothing',
      build: build,
      seed: () => CartState(status: CartStatus.inProcess, finDoc: emptyCart),
      act: (bloc) => bloc.add(CartFetch(emptyCart)),
      expect: () => <CartState>[],
      verify: (_) => verifyZeroInteractions(restClient),
    );
  });

  // https://github.com/growerp/growerp/issues/39
  group('CartFetch saved cart', () {
    blocTest<CartBloc, CartState>(
      'CartFetch_savedCart_restoresIt',
      setUp: () async {
        when(
          () => restClient.getItemTypes(sales: true),
        ).thenAnswer((_) async => ItemTypes());
        await PersistFunctions.persistFinDoc(
          emptyCart.copyWith(description: 'saved cart'),
        );
      },
      build: build,
      act: (bloc) => bloc.add(CartFetch(emptyCart)),
      expect: () => [
        isA<CartState>().having(
          (s) => s.finDoc.description,
          'description',
          'saved cart',
        ),
      ],
    );
  });

  group('CartAdd', () {
    blocTest<CartBloc, CartState>(
      'CartAdd_secondItem_insertsFirstWithSeqAndTotalsPriceTimesQuantity',
      build: build,
      seed: () => CartState(
        status: CartStatus.inProcess,
        finDoc: emptyCart.copyWith(
          items: [item('first', '10', '2').copyWith(itemSeqId: '1')],
        ),
      ),
      act: (bloc) => bloc.add(
        CartAdd(
          finDoc: emptyCart.copyWith(description: 'my order'),
          newItem: item('second', '5', '3'),
        ),
      ),
      expect: () => [
        cartState(CartStatus.inProcess).having(
          (s) => s.finDoc,
          'finDoc',
          isA<FinDoc>()
              .having((d) => d.description, 'description', 'my order')
              .having(
                (d) => d.items.map((i) => '${i.itemSeqId}:${i.description}'),
                'items',
                ['2:second', '1:first'],
              )
              .having((d) => d.grandTotal, 'grandTotal', Decimal.parse('35')),
        ),
      ],
    );
  });

  group('CartDeleteItem', () {
    blocTest<CartBloc, CartState>(
      'CartDeleteItem_firstOfThree_renumbersRemainingItems',
      build: build,
      seed: () => CartState(
        status: CartStatus.inProcess,
        finDoc: emptyCart.copyWith(
          items: [
            item('a', '1', '1'),
            item('b', '1', '1'),
            item('c', '1', '1'),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const CartDeleteItem(0)),
      expect: () => [
        cartState(CartStatus.inProcess).having(
          (s) => s.finDoc.items.map((i) => '${i.itemSeqId}:${i.description}'),
          'items',
          ['1:b', '2:c'],
        ),
      ],
    );
  });

  // https://github.com/growerp/growerp/issues/38
  group('CartDeleteItem total', () {
    blocTest<CartBloc, CartState>(
      'CartDeleteItem_twoItemsLeft_recalculatesTotal',
      build: build,
      seed: () => CartState(
        status: CartStatus.inProcess,
        finDoc: emptyCart.copyWith(
          items: [
            item('a', '1', '1'),
            item('b', '10', '2'),
            item('c', '5', '3'),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const CartDeleteItem(0)),
      expect: () => [
        cartState(
          CartStatus.inProcess,
        ).having((s) => s.finDoc.grandTotal, 'grandTotal', Decimal.parse('35')),
      ],
    );
  });

  group('CartHeader', () {
    blocTest<CartBloc, CartState>(
      'CartHeader_changedDoc_replacesCartDoc',
      build: build,
      seed: () => CartState(status: CartStatus.inProcess, finDoc: emptyCart),
      act: (bloc) =>
          bloc.add(CartHeader(emptyCart.copyWith(description: 'header'))),
      expect: () => [
        cartState(
          CartStatus.inProcess,
          finDoc: emptyCart.copyWith(description: 'header'),
        ),
      ],
    );
  });

  group('CartCreateFinDoc', () {
    final order = emptyCart.copyWith(items: [item('a', '1', '1')]);

    blocTest<CartBloc, CartState>(
      'CartCreateFinDoc_cart_sendsUpdateToFinDocBlocAndEmptiesCart',
      build: build,
      seed: () => CartState(status: CartStatus.inProcess, finDoc: order),
      act: (bloc) => bloc.add(CartCreateFinDoc(order)),
      expect: () => [
        cartState(CartStatus.saving),
        cartState(CartStatus.complete, finDoc: emptyCart),
        cartState(CartStatus.inProcess, finDoc: emptyCart),
      ],
      verify: (_) =>
          verify(() => finDocBloc.add(FinDocUpdate(order))).called(1),
    );
  });

  group('CartCancelFinDoc', () {
    blocTest<CartBloc, CartState>(
      'CartCancelFinDoc_order_sendsCancelledStatusAndEmptiesCart',
      build: build,
      seed: () => CartState(status: CartStatus.inProcess, finDoc: order1),
      act: (bloc) => bloc.add(CartCancelFinDoc(order1)),
      expect: () => [
        cartState(CartStatus.complete),
        cartState(CartStatus.inProcess, finDoc: emptyCart),
      ],
      verify: (_) => verify(
        () => finDocBloc.add(
          FinDocUpdate(order1.copyWith(status: FinDocStatusVal.cancelled)),
        ),
      ).called(1),
    );
  });
}
