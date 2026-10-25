/*
 * Regression test for https://github.com/growerp/growerp/issues/31:
 * a company name typed in the lead dialog was not carried over into the
 * company dialog opened with 'add new related company'.
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../shared/mocks.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockRestClient restClient;
  late MockAuthBloc authBloc;

  setUp(() {
    restClient = MockRestClient();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      AuthState(
        status: AuthStatus.authenticated,
        authenticate: Authenticate(
          ownerPartyId: 'OWNER',
          user: User(partyId: 'ADMIN', userGroup: UserGroup.admin),
        ),
      ),
    );
    when(
      () => restClient.getCompany(
        companyPartyId: any(named: 'companyPartyId'),
        ownerPartyId: any(named: 'ownerPartyId'),
        role: any(named: 'role'),
        start: any(named: 'start'),
        limit: any(named: 'limit'),
        searchString: any(named: 'searchString'),
        isForDropDown: any(named: 'isForDropDown'),
      ),
    ).thenAnswer((_) async => Companies());
  });

  Future<void> pumpLeadDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // the test font is wider than the real one: ignore overflow of the
    // fixed-width dialogs, keep every other error
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      onError?.call(details);
    };
    addTearDown(() => FlutterError.onError = onError);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          RepositoryProvider<RestClient>.value(value: restClient),
          RepositoryProvider<String>.value(value: 'AppAdmin'),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider(create: (_) => UserBloc(restClient, Role.lead)),
          BlocProvider(create: (_) => CompanyBloc(restClient, Role.lead)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            ...UserCompanyLocalizations.localizationsDelegates,
            CoreLocalizations.delegate,
          ],
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: const [
              Breakpoint(start: 0, end: 500, name: MOBILE),
              Breakpoint(start: 501, end: double.infinity, name: DESKTOP),
            ],
          ),
          home: Scaffold(
            body: UserDialogStateFull(user: User(role: Role.lead)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('NewCompany_typedName_isCarriedIntoCompanyDialog', (
    tester,
  ) async {
    await pumpLeadDialog(tester);

    final companyField = find.descendant(
      of: find.byKey(const Key('userCompanyName')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(companyField, 'Acme Lead Corp');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('newCompany')));
    await tester.tap(find.byKey(const Key('newCompany')));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('companyName')),
    );
    expect(nameField.controller!.text, 'Acme Lead Corp');
  });
}
