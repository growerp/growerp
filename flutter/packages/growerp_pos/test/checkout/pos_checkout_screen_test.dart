import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../shared/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockRestClient restClient;
  late MockAuthBloc authBloc;
  final beer = PosCatalogItem(
    productId: 'P1',
    productName: 'Beer',
    price: Decimal.fromInt(5),
  );

  AuthState authFor(UserGroup group) => AuthState(
    authenticate: Authenticate(user: User(userGroup: group)),
  );

  setUpAll(() {
    registerFallbackValue(<PosLine>[]);
    registerFallbackValue(<PosTender>[]);
    registerFallbackValue(<PosRefundLine>[]);
  });
  setUp(() {
    restClient = MockRestClient();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(authFor(UserGroup.employee));
    when(
      () => restClient.getPosCatalog(),
    ).thenAnswer((_) async => PosCatalog(items: [beer], currencyId: 'USD'));
    when(() => restClient.getPosQuote(lines: any(named: 'lines'))).thenAnswer(
      (_) async =>
          PosQuote(taxTotal: Decimal.zero, grandTotal: Decimal.fromInt(5)),
    );
    when(
      () => restClient.createPosSale(
        clientSaleId: any(named: 'clientSaleId'),
        terminalName: any(named: 'terminalName'),
        lines: any(named: 'lines'),
        tenders: any(named: 'tenders'),
      ),
    ).thenAnswer(
      (_) async => PosSale(
        currencyId: 'USD',
        grandTotal: Decimal.fromInt(5),
        changeAmount: Decimal.zero,
        lines: [
          PosSaleLine(
            description: 'Beer',
            quantity: Decimal.one,
            lineTotal: Decimal.fromInt(5),
          ),
        ],
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 500, name: MOBILE),
            Breakpoint(start: 501, end: 1920, name: DESKTOP),
          ],
        ),
        localizationsDelegates: [
          ...CoreLocalizations.localizationsDelegates,
          PosLocalizations.delegate,
        ],
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              ...getPosBlocProviders(restClient),
            ],
            child: const PosCheckoutScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (name, size) in [
    ('tablet', const Size(1280, 800)),
    ('phone', const Size(412, 800)),
  ]) {
    testWidgets('a sale from tile to receipt on a $name', (tester) async {
      await pump(tester, size);
      expect(find.byKey(const Key('posCartEmpty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('posItem0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('posLine0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('posPay')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('PosTenderDialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('posCash')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('posComplete')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('PosReceiptDialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('posNewSale')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('posCartEmpty')), findsOneWidget);
    });
  }

  testWidgets('a cashier sees no refund button', (tester) async {
    await pump(tester, const Size(1280, 800));
    expect(find.byKey(const Key('posRefund')), findsNothing);
  });

  testWidgets('an admin sees the refund button', (tester) async {
    when(() => authBloc.state).thenReturn(authFor(UserGroup.admin));
    await pump(tester, const Size(1280, 800));
    expect(find.byKey(const Key('posRefund')), findsOneWidget);
  });

  testWidgets('a refund from receipt number to the amount', (tester) async {
    when(() => authBloc.state).thenReturn(authFor(UserGroup.admin));
    when(() => restClient.getPosSaleLookup(search: '100')).thenAnswer(
      (_) async => PosSale(
        clientSaleId: 'S1',
        currencyId: 'USD',
        lines: [
          PosSaleLine(
            orderItemSeqId: '01',
            description: 'Beer',
            price: Decimal.fromInt(5),
            returnableQuantity: Decimal.fromInt(2),
          ),
        ],
      ),
    );
    when(
      () => restClient.createPosRefund(
        clientRefundId: any(named: 'clientRefundId'),
        clientSaleId: 'S1',
        lines: any(named: 'lines'),
        restock: true,
      ),
    ).thenAnswer(
      (_) async => PosRefund(
        amount: Decimal.fromInt(5),
        method: 'PiCash',
        currencyId: 'USD',
      ),
    );
    await pump(tester, const Size(1280, 800));

    await tester.tap(find.byKey(const Key('posRefund')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('posRefundSearch')), '100');
    await tester.tap(find.byKey(const Key('posRefundFind')));
    await tester.pumpAndSettle();

    final confirm = find.byKey(const Key('posRefundConfirm'));
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    await tester.tap(find.byKey(const Key('posRefundPlus0')));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posRefundAmount')), findsOneWidget);
    await tester.tap(find.byKey(const Key('posRefundDone')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('PosRefundDialog')), findsNothing);
  });

  testWidgets('pay stays off without lines', (tester) async {
    await pump(tester, const Size(1280, 800));
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('posPay')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a scanned code lands in the cart', (tester) async {
    when(
      () => restClient.getPosProductByBarcode(barcode: '871'),
    ).thenAnswer((_) async => beer);
    await pump(tester, const Size(1280, 800));

    await tester.enterText(find.byKey(const Key('posSearch')), '871');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posLine0')), findsOneWidget);
  });
}
