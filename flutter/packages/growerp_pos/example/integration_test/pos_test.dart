// ignore_for_file: depend_on_referenced_packages
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos_example/router_builder.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  testWidgets('GrowERP point of sale test', (tester) async {
    RestClient restClient = RestClient(await buildDioClient());
    await CommonTest.startTestApp(
      tester,
      createPosExampleRouter(),
      posMenuConfig,
      extraDelegates,
      restClient: restClient,
      blocProviders: getExampleBlocProviders(restClient, 'AppShop'),
      applicationId: 'AppShop',
      title: "Point of sale test",
      clear: true,
    );
    await CommonTest.createCompanyAndAdmin(tester);
    final random = CommonTest.getRandom();

    await restClient.createProduct(
      product: Product(
        productName: 'Haircut$random',
        productTypeId: 'Service',
        price: Decimal.parse('10'),
        barcode: 'B$random',
      ),
      applicationId: 'AppShop',
    );
    await restClient.createTaxRate(
      taxRate: TaxRate(taxName: 'VAT', taxPercentage: Decimal.parse('10')),
    );

    await CommonTest.tapByKey(tester, 'posRefresh', seconds: 2);
    expect(find.byKey(const Key('posItem0')), findsOneWidget);

    // by tile and by barcode, the same product twice
    await CommonTest.tapByKey(tester, 'posItem0', seconds: 2);
    await CommonTest.enterText(tester, 'posSearch', 'B$random');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(
      tester.widget<Text>(find.byKey(const Key('posLineQuantity0'))).data,
      '2',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('posTotal'))).data,
      contains('22'),
    );

    await CommonTest.tapByKey(tester, 'posPay', seconds: 1);
    await CommonTest.enterText(tester, 'posAmount', '30');
    await CommonTest.tapByKey(tester, 'posCash', seconds: 1);
    await CommonTest.tapByKey(tester, 'posComplete', seconds: 8);

    expect(find.byKey(const Key('PosReceiptDialog')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('posReceiptTotal'))).data,
      contains('22'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('posReceiptChange'))).data,
      contains('8'),
    );

    final receiptNumber = tester
        .widget<Text>(find.byKey(const Key('posReceiptNumber')))
        .data!;
    await CommonTest.tapByKey(tester, 'posNewSale', seconds: 1);
    expect(find.byKey(const Key('posCartEmpty')), findsOneWidget);

    // one of the two comes back
    await CommonTest.tapByKey(tester, 'posRefund', seconds: 1);
    await CommonTest.enterText(tester, 'posRefundSearch', receiptNumber);
    await CommonTest.tapByKey(tester, 'posRefundFind', seconds: 2);
    await CommonTest.tapByKey(tester, 'posRefundPlus0', seconds: 1);
    await CommonTest.tapByKey(tester, 'posRefundConfirm', seconds: 8);
    expect(
      tester.widget<Text>(find.byKey(const Key('posRefundAmount'))).data,
      contains('11'),
    );
    await CommonTest.tapByKey(tester, 'posRefundDone', seconds: 1);
  });
}
