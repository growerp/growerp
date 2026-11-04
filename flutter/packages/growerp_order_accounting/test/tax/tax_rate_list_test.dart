import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  final vat = TaxRate(
    taxRateId: 'R1',
    taxName: 'VAT',
    taxPercentage: Decimal.fromInt(21),
  );

  setUpAll(() => registerFallbackValue(TaxRate()));
  setUp(() {
    restClient = MockRestClient();
    when(
      () => restClient.getTaxRates(),
    ).thenAnswer((_) async => TaxRates(taxRates: [vat]));
    when(
      () => restClient.getCategory(limit: 100),
    ).thenAnswer((_) async => Categories());
  });

  Future<void> pumpList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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
          OrderAccountingLocalizations.delegate,
        ],
        home: Scaffold(
          body: BlocProvider(
            create: (_) => TaxRateBloc(restClient),
            child: const TaxRateList(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the list shows a rate and its row opens the dialog', (
    tester,
  ) async {
    await pumpList(tester);
    expect(find.byKey(const Key('name0')), findsOneWidget);
    expect(find.text('VAT'), findsOneWidget);
    expect(find.byKey(const Key('pricesIncludeTax')), findsOneWidget);

    await tester.tap(find.byKey(const Key('name0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('TaxRateDialog')), findsOneWidget);
    expect(find.byKey(const Key('delete')), findsOneWidget);
  });

  testWidgets('a new rate needs a name and a percentage', (tester) async {
    await pumpList(tester);
    await tester.tap(find.byKey(const Key('addNew')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete')), findsNothing);

    await tester.tap(find.byKey(const Key('update')));
    await tester.pumpAndSettle();
    verifyNever(() => restClient.createTaxRate(taxRate: any(named: 'taxRate')));
  });
}
