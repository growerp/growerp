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
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockRestClient restClient;
  late MockAuthBloc authBloc;

  final burger = PosCatalogItem(
    productId: 'P1',
    productName: 'Burger',
    price: Decimal.fromInt(10),
  );
  final group = PosModifierGroup(
    groupId: 'G1',
    groupName: 'Sauce',
    minSelect: 1,
    maxSelect: 1,
    productIds: ['P1'],
    modifiers: [
      PosModifier(modifierId: 'M1', modifierName: 'Mayo'),
      PosModifier(
        modifierId: 'M2',
        modifierName: 'Truffle',
        priceDelta: Decimal.fromInt(2),
      ),
    ],
  );
  PosTabLine line(String status) => PosTabLine(
    orderId: 'O1',
    orderItemSeqId: '01',
    description: 'Burger (Truffle)',
    quantity: Decimal.one,
    price: Decimal.fromInt(12),
    kitchenStatus: status,
  );
  PosTab tab(List<PosTabLine> lines) => PosTab(
    tabId: 'T1',
    orderId: 'O1',
    tableName: 'Table 1',
    currencyId: 'USD',
    lines: lines,
    grandTotal: lines.isEmpty ? Decimal.zero : Decimal.fromInt(12),
  );

  setUpAll(() {
    registerFallbackValue(<PosTender>[]);
    registerFallbackValue(<String>[]);
  });
  setUp(() {
    restClient = MockRestClient();
    authBloc = MockAuthBloc();
    SharedPreferences.setMockInitialValues({});
    when(() => authBloc.state).thenReturn(
      AuthState(
        authenticate: Authenticate(user: User(userGroup: UserGroup.employee)),
      ),
    );
    when(
      () => restClient.getPosShift(terminalName: 'Till 1'),
    ).thenAnswer((_) async => PosShift(shiftId: 'S1', terminalName: 'Till 1'));
    when(() => restClient.getPosCatalog()).thenAnswer(
      (_) async => PosCatalog(
        items: [burger],
        modifierGroups: [group],
        currencyId: 'USD',
      ),
    );
    when(() => restClient.getPosFloorPlan()).thenAnswer(
      (_) async => PosTables(
        tables: [
          PosTable(
            assetId: 'A1',
            tableName: 'Table 1',
            x: 0,
            y: 0,
            status: 'free',
          ),
        ],
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          ...getPosBlocProviders(restClient),
        ],
        child: MaterialApp(
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
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a free table opens a tab, a chosen modifier goes on the line', (
    tester,
  ) async {
    when(
      () => restClient.openPosTab(tableAssetId: 'A1'),
    ).thenAnswer((_) async => tab([]));
    when(
      () => restClient.addPosTabLine(
        tabId: 'T1',
        productId: 'P1',
        quantity: Decimal.one,
        modifierIds: ['M2'],
      ),
    ).thenAnswer((_) async => tab([line('New')]));
    when(
      () => restClient.sendPosTab(tabId: 'T1'),
    ).thenAnswer((_) async => tab([line('Sent')]));
    await pump(tester, const PosFloorScreen());

    await tester.tap(find.byKey(const Key('posTable0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('PosTabScreen')), findsOneWidget);
    expect(find.byKey(const Key('posTabEmpty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('posItem0')));
    await tester.pumpAndSettle();
    final add = find.byKey(const Key('posModifierAdd'));
    expect(tester.widget<ElevatedButton>(add).onPressed, isNull);
    await tester.tap(find.byKey(const Key('posModifierTruffle')));
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('posTabLine0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('posSend')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('posSend'))).onPressed,
      isNull,
    );
  });

  testWidgets('the kitchen shows a ticket and a tap moves the line on', (
    tester,
  ) async {
    when(() => restClient.getPosKitchen()).thenAnswer(
      (_) async => PosTickets(
        tickets: [
          PosTicket(
            ticketId: 'K1',
            tableName: 'Table 1',
            sentDate: DateTime.now(),
            lines: [line('Sent')],
          ),
        ],
      ),
    );
    when(
      () => restClient.updatePosKitchenLine(
        orderId: 'O1',
        orderItemSeqId: '01',
        kitchenStatus: 'Ready',
      ),
    ).thenAnswer((_) async {});
    await pump(tester, const PosKitchenScreen());
    expect(find.text('Table 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('posTicketLine0_0')));
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => restClient.updatePosKitchenLine(
        orderId: 'O1',
        orderItemSeqId: '01',
        kitchenStatus: 'Ready',
      ),
    ).called(1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an admin adds a table from the floor', (tester) async {
    when(() => authBloc.state).thenReturn(
      AuthState(
        authenticate: Authenticate(user: User(userGroup: UserGroup.admin)),
      ),
    );
    when(
      () => restClient.createPosTable(
        table: PosTable(
          tableName: 'Patio',
          x: 1,
          y: 0,
          seats: 4,
          areaName: '',
          shape: 'square',
        ),
      ),
    ).thenAnswer((_) async => PosTable(assetId: 'A2'));
    await pump(tester, const PosFloorScreen());

    await tester.tap(find.byKey(const Key('posFloorEdit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('posTableAdd')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('posTableName')), 'Patio');
    await tester.tap(find.byKey(const Key('posTableSave')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('PosTableDialog')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  void asAdmin() => when(() => authBloc.state).thenReturn(
    AuthState(
      authenticate: Authenticate(user: User(userGroup: UserGroup.admin)),
    ),
  );

  Future<void> openSentTab(WidgetTester tester) async {
    when(
      () => restClient.openPosTab(tableAssetId: 'A1'),
    ).thenAnswer((_) async => tab([line('Sent')]));
    await pump(tester, const PosFloorScreen());
    await tester.tap(find.byKey(const Key('posTable0')));
    await tester.pumpAndSettle();
  }

  testWidgets('a waiter enters orders without a shift or the till', (
    tester,
  ) async {
    when(
      () => restClient.getPosShift(terminalName: 'Till 1'),
    ).thenAnswer((_) async => PosShift());
    await pump(tester, const PosFloorScreen());
    expect(find.byKey(const Key('posTable0')), findsOneWidget);
    expect(find.byKey(const Key('posTill')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a waiter cannot pay, split or void what the kitchen saw', (
    tester,
  ) async {
    await openSentTab(tester);
    expect(find.byKey(const Key('posTabLine0')), findsOneWidget);
    expect(find.byKey(const Key('posPay')), findsNothing);
    expect(find.byKey(const Key('posSplit')), findsNothing);
    expect(find.byKey(const Key('posTabVoid0')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an admin pays, splits and voids', (tester) async {
    asAdmin();
    await openSentTab(tester);
    expect(find.byKey(const Key('posPay')), findsOneWidget);
    expect(find.byKey(const Key('posSplit')), findsOneWidget);
    expect(find.byKey(const Key('posTabVoid0')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an admin needs an open shift for the floor', (tester) async {
    asAdmin();
    when(
      () => restClient.getPosShift(terminalName: 'Till 1'),
    ).thenAnswer((_) async => PosShift());
    await pump(tester, const PosFloorScreen());
    expect(find.byKey(const Key('posTable0')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a cashier cannot edit the floor', (tester) async {
    await pump(tester, const PosFloorScreen());
    expect(find.byKey(const Key('posFloorEdit')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
