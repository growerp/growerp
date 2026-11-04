// ignore_for_file: depend_on_referenced_packages
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:growerp_pos_example/router_builder.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP restaurant test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createRestaurantExampleRouter(),
      restaurantMenuConfig,
      extraDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppRestaurant'),
      applicationId: 'AppRestaurant',
      title: "Restaurant test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    final random = CommonTest.getRandom();

    final burger = await restClient.createProduct(
      product: Product(
        productName: 'Burger$random',
        productTypeId: 'Service',
        price: Decimal.parse('10'),
      ),
      applicationId: 'AppRestaurant',
    );
    await restClient.storePosModifierGroup(
      group: PosModifierGroup(
        groupName: 'Sauce',
        minSelect: 1,
        maxSelect: 1,
        modifiers: [
          PosModifier(modifierName: 'Mayo', priceDelta: Decimal.zero),
          PosModifier(modifierName: 'Truffle', priceDelta: Decimal.fromInt(2)),
        ],
        productIds: [burger.productId],
      ),
    );
    await restClient.createPosTable(
      table: PosTable(tableName: 'Table$random', x: 0, y: 0, seats: 4),
    );
    final terrace = await restClient.createPosTable(
      table: PosTable(tableName: 'Terrace$random', x: 1, y: 0, seats: 2),
    );
    final beer = await restClient.createProduct(
      product: Product(
        productName: 'Beer$random',
        productTypeId: 'Service',
        price: Decimal.parse('5'),
      ),
      applicationId: 'AppRestaurant',
    );

    await CommonTest.enterText(tester, 'posOpeningFloat', '50');
    await CommonTest.tapByKey(tester, 'posOpenShift', seconds: 3);
    final floor = find.byType(PosFloorScreen);
    tester.element(floor).read<PosFloorBloc>().add(const PosFloorFetch());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // the waiter takes the order
    await CommonTest.tapByKey(tester, 'posTable0', seconds: 3);
    await tester.tap(find.text('Burger$random'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await CommonTest.tapByKey(tester, 'posModifierTruffle', seconds: 1);
    await CommonTest.tapByKey(tester, 'posModifierAdd', seconds: 3);
    expect(
      tester.widget<Text>(find.byKey(const Key('posTabTotal'))).data,
      contains('12'),
    );
    await CommonTest.tapByKey(tester, 'posSend', seconds: 3);
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // the kitchen cooks it
    GoRouter.of(tester.element(floor)).go('/kitchen');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const Key('posTicket0')), findsOneWidget);
    await CommonTest.tapByKey(tester, 'posTicketLine0_0', seconds: 3);

    // another waiter sends while the kitchen watches: the signal brings it in
    // well before the poll of 15 seconds
    final order = await restClient.openPosTab(tableAssetId: terrace.assetId);
    await restClient.addPosTabLine(
      tabId: order.tabId!,
      productId: beer.productId,
      quantity: Decimal.one,
    );
    await restClient.sendPosTab(tabId: order.tabId!);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const Key('posTicket1')), findsOneWidget);

    // the floor shows it is ready, the guests pay in two
    GoRouter.of(tester.element(find.byType(PosKitchenScreen))).go('/');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const Key('posTableTotal0')), findsOneWidget);
    await CommonTest.tapByKey(tester, 'posTable0', seconds: 3);
    await CommonTest.tapByKey(tester, 'posSplit', seconds: 1);
    await CommonTest.tapByKey(tester, 'posSplitCalculate', seconds: 3);
    expect(
      tester.widget<Text>(find.byKey(const Key('posShareAmount0'))).data,
      contains('6'),
    );
    await CommonTest.tapByKey(tester, 'posSplitPay', seconds: 8);
    expect(find.byKey(const Key('PosReceiptDialog')), findsOneWidget);
    await CommonTest.tapByKey(tester, 'posNewSale', seconds: 3);

    // the table is free again
    expect(find.byKey(const Key('posTableTotal0')), findsNothing);
  });
}
