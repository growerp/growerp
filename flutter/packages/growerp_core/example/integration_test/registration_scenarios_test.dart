// ignore_for_file: dangling_library_doc_comments
/// Registration, first and second login scenarios for every app, as described
/// in docs/Registration_and_First_Login_Scenarios.md.
///
/// This test also bootstraps the GROWERP owner on a fresh backend (scenario A):
/// CI runs it before any other integration test (see ci/test/run_tests.sh), and
/// CommonTest.login() fails when it meets a backend where it has not run yet.
///
/// Scenarios, run in this order:
/// - A: the very first account on a new system becomes the GROWERP admin
/// - B: a new tenant with demo data, for every app
/// - C: a user joining an existing company
/// - X: the same user in a second app gets no welcome again
/// - D: an expired trial asks for payment, also for a non admin user
/// - S: the support app has no registration and only admits system support
///
/// The dialogs are driven one by one here instead of with CommonTest.login(),
/// because that helper dismisses the very dialogs these scenarios check.

// ignore_for_file: depend_on_referenced_packages
import 'package:core_example/router_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growerp_adk/growerp_adk.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// debug builds register every user with this password
const String _password = 'qqqqqq9!';

/// the apps where a visitor registers a new company
const List<String> _tenantApps = [
  'AppAdmin',
  'AppHotel',
  'AppRental',
  'AppFreelance',
  'AppMarketing',
  'AppAgents',
];

const Timeout _timeout = Timeout(Duration(minutes: 20));

/// admin email and company of the tenant registered per app in scenario B
final Map<String, ({String email, Company company})> _tenants = {};

/// user who joined the AppAdmin tenant in scenario C
String? _joinerEmail;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
  });

  tearDown(() => EvaluationTest.resetTestDaysOffset());

  testWidgets('A: first account on a new system becomes the GROWERP admin', (
    tester,
  ) async {
    await _start(tester, 'AppAdmin');
    final email = await _email('growerp');
    await _register(tester, email);
    await _login(tester, email);

    expect(
      await _waitFor(tester, ['companyName', 'HomeFormAuth'], seconds: 60),
      'companyName',
      reason: 'first login of a new admin must show the company setup',
    );
    if (CommonTest.getFormBuilderTextFieldByName(tester, 'companyName') !=
        'GrowERP') {
      // GROWERP already has its admin: this registration created an ordinary
      // tenant, which is left unfinished.
      debugPrint('Scenario A skipped: GROWERP was set up before');
      await CommonTest.tapByKey(tester, 'cancel');
      return;
    }
    expect(
      find.byKey(const Key('demoData')),
      findsNothing,
      reason: 'the GROWERP company never loads demo data',
    );
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    expect(
      await _waitFor(tester, [
        'HomeFormAuth',
        'setupInProgress',
        'startTrial',
        'skipAssessment',
      ], seconds: 300),
      'HomeFormAuth',
    );
    await _expectNone(tester, [
      'setupInProgress',
      'startTrial',
      'skipAssessment',
    ], reason: 'GROWERP gets no trial, welcome or assessment');

    await _secondLogin(tester, email);
  }, timeout: _timeout);

  for (final app in _tenantApps) {
    testWidgets('B: new tenant with demo data in $app', (tester) async {
      await _start(tester, app);
      final email = await _email(app.substring(3).toLowerCase());
      await _register(tester, email);
      await _login(tester, email);

      // company setup
      expect(
        await _waitFor(tester, ['companyName', 'HomeFormAuth'], seconds: 60),
        'companyName',
      );
      expect(
        CommonTest.getFormBuilderTextFieldByName(tester, 'companyName'),
        'Company ${email.split('@').first}',
        reason: 'debug builds prefill the company name from the email',
      );
      // the currency field replaces a spinner once the currencies are loaded
      if (showAccountingSetup(app)) {
        expect(await _waitFor(tester, ['currency']), 'currency');
      } else {
        await _expectNone(tester, [
          'currency',
        ], reason: 'apps without accounting ask no currency');
      }
      expect(find.byKey(const Key('demoData')), findsOneWidget);
      final companyName = 'Scenario $app ${email.split('@').first}';
      await CommonTest.enterText(tester, 'companyName', companyName);
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pump();

      // demo data, ticked by default in debug builds
      expect(
        await _waitFor(tester, [
          'setupInProgress',
          'startTrial',
          'HomeFormAuth',
        ], seconds: 180),
        'setupInProgress',
      );
      await _waitForDemoData(tester);

      // welcome sequence of a new tenant admin
      expect(
        await _waitFor(tester, ['startTrial', 'skipAssessment'], seconds: 60),
        'startTrial',
      );
      await EvaluationTest.startTrial(tester);
      expect(
        await _waitFor(tester, ['skipAssessment'], seconds: 60),
        'skipAssessment',
      );
      await CommonTest.tapByKey(tester, 'skipAssessment', settle: false);
      expect(await _waitFor(tester, ['HomeFormAuth']), 'HomeFormAuth');
      await _expectNone(tester, ['startTrial', 'skipAssessment']);

      final company = tester
          .element(find.byKey(const Key('HomeFormAuth')))
          .read<AuthBloc>()
          .state
          .authenticate!
          .company!;
      expect(company.name, companyName);
      _tenants[app] = (email: email, company: company);

      await _secondLogin(tester, email);
    }, timeout: _timeout);
  }

  testWidgets('C: user joins an existing company', (tester) async {
    final tenant = _tenants['AppAdmin'];
    expect(tenant, isNotNull, reason: 'needs the AppAdmin tenant of B');
    await _start(tester, 'AppAdmin', company: tenant!.company);
    expect(await _waitFor(tester, ['newUserButton']), 'newUserButton');
    expect(
      find.textContaining('${tenant.company.name}'),
      findsWidgets,
      reason: 'the start screen names the company to join',
    );

    final email = await _email('joiner');
    await _register(tester, email);
    await _login(tester, email);
    expect(
      await _waitFor(tester, ['skipAssessment', 'startTrial'], seconds: 60),
      'skipAssessment',
      reason: 'a joiner gets no trial, only the assessment',
    );
    expect(
      find.byType(TenantSetupDialog),
      findsNothing,
      reason: 'a joiner gets no company setup',
    );
    await CommonTest.tapByKey(tester, 'skipAssessment', settle: false);
    expect(await _waitFor(tester, ['HomeFormAuth']), 'HomeFormAuth');
    await _expectNone(tester, ['startTrial', 'skipAssessment']);
    _joinerEmail = email;

    await _secondLogin(tester, email);
  }, timeout: _timeout);

  testWidgets('X: same user in a second app gets no welcome again', (
    tester,
  ) async {
    final tenant = _tenants['AppAdmin'];
    expect(tenant, isNotNull, reason: 'needs the AppAdmin tenant of B');
    await _start(tester, 'AppHotel');
    await _login(tester, tenant!.email);
    await _expectDashboardOnly(tester);
  }, timeout: _timeout);

  testWidgets('D: expired trial asks a non admin user for payment', (
    tester,
  ) async {
    expect(_joinerEmail, isNotNull, reason: 'needs the joiner of C');
    await _start(tester, 'AppAdmin');
    EvaluationTest.setTestDaysOffset(15);
    await _login(tester, _joinerEmail!);
    expect(
      await _waitFor(tester, ['paymentForm', 'HomeFormAuth'], seconds: 60),
      'paymentForm',
    );
  }, timeout: _timeout);

  testWidgets('D: expired trial, admin pays and continues', (tester) async {
    final tenant = _tenants['AppAdmin'];
    expect(tenant, isNotNull, reason: 'needs the AppAdmin tenant of B');
    await _start(tester, 'AppAdmin');
    EvaluationTest.setTestDaysOffset(15);
    await _login(tester, tenant!.email);
    expect(
      await _waitFor(tester, ['paymentForm', 'HomeFormAuth'], seconds: 60),
      'paymentForm',
    );
    await EvaluationTest.submitPayment(tester);
    await _expectDashboardOnly(tester);
  }, timeout: _timeout);

  testWidgets('S: support app has no registration, admits system support', (
    tester,
  ) async {
    final tenant = _tenants['AppHotel'];
    expect(tenant, isNotNull, reason: 'needs the AppHotel tenant of B');
    await _start(tester, 'AppSupport');
    expect(await _waitFor(tester, ['loginButton']), 'loginButton');
    expect(find.byKey(const Key('newUserButton')), findsNothing);

    // an ordinary tenant admin is refused
    await _login(tester, tenant!.email);
    expect(
      await _waitForText(tester, 'Not authorized for the support application'),
      isTrue,
    );
    expect(find.byKey(const Key('HomeFormAuth')), findsNothing);

    // system support gets in without setup or trial, from the login dialog
    // that stayed open
    await CommonTest.waitForSnackbarToGo(tester);
    await CommonTest.enterText(tester, 'username', 'SystemSupport');
    await CommonTest.enterText(tester, 'password', 'moqui');
    await CommonTest.pressLogin(tester);
    expect(
      await _waitFor(tester, [
        'HomeFormAuth',
        'startTrial',
        'paymentForm',
      ], seconds: 60),
      'HomeFormAuth',
    );
    await CommonTest.skipOnboardingIfPresent(tester);
    await _expectNone(tester, ['startTrial', 'paymentForm']);
    expect(find.byType(TenantSetupDialog), findsNothing);
  }, timeout: _timeout);

  testWidgets('N: academy app has no registration', (tester) async {
    await _start(tester, 'AppAcademy');
    expect(await _waitFor(tester, ['loginButton']), 'loginButton');
    expect(find.byKey(const Key('newUserButton')), findsNothing);
  }, timeout: _timeout);
}

Future<void> _start(
  WidgetTester tester,
  String applicationId, {
  Company? company,
}) async {
  final restClient = RestClient(await buildDioClient());
  final router = createDynamicCoreRouter([
    coreMenuConfig,
  ], rootNavigatorKey: GlobalKey<NavigatorState>());
  await CommonTest.startTestApp(
    tester,
    router,
    coreMenuConfig,
    // the delegates of the core example app: the dashboard of a joined user
    // shows company screens of growerp_user_company, whose .of(context)!
    // crashes without its delegate
    const [
      ...CoreLocalizations.localizationsDelegates,
      UserCompanyLocalizations.delegate,
      AdkLocalizations.delegate,
    ],
    blocProviders: getUserCompanyBlocProviders(restClient, applicationId),
    widgetRegistrations: coreWidgetRegistrations,
    restClient: restClient,
    clear: true,
    applicationId: applicationId,
    company: company,
    title: 'Registration scenarios: $applicationId',
  );
}

/// unique email per run: startTestApp gives every run a random sequence
Future<String> _email(String prefix) async {
  final test = await PersistFunctions.getTest();
  await PersistFunctions.persistTest(
    test.copyWith(sequence: test.sequence + 1),
  );
  return 'scenario$prefix${test.sequence}@example.com';
}

Future<void> _register(WidgetTester tester, String email) async {
  expect(await _waitFor(tester, ['newUserButton']), 'newUserButton');
  await CommonTest.tapByKey(tester, 'newUserButton');
  await CommonTest.enterText(tester, 'firstName', 'Scenario');
  await CommonTest.enterText(tester, 'lastName', 'Tester');
  await CommonTest.enterText(tester, 'email', email);
  await CommonTest.tapByKey(
    tester,
    'newUserButton',
    seconds: CommonTest.waitTime,
    settle: false,
  );
  await CommonTest.waitForSnackbarToGo(tester);
  expect(
    await _waitFor(tester, ['loginButton']),
    'loginButton',
    reason: 'registration returns to the start screen',
  );
}

Future<void> _login(
  WidgetTester tester,
  String username, {
  String password = _password,
}) async {
  expect(await _waitFor(tester, ['loginButton']), 'loginButton');
  await CommonTest.pressLoginButton(tester);
  await CommonTest.enterText(tester, 'username', username);
  await CommonTest.enterText(tester, 'password', password);
  await CommonTest.pressLogin(tester);
}

/// logout and login again: straight to the dashboard, no dialogs
Future<void> _secondLogin(WidgetTester tester, String email) async {
  await CommonTest.logout(tester);
  await _login(tester, email);
  await _expectDashboardOnly(tester);
}

Future<void> _expectDashboardOnly(WidgetTester tester) async {
  expect(
    await _waitFor(tester, [
      'HomeFormAuth',
      'setupInProgress',
      'paymentForm',
      'startTrial',
      'skipAssessment',
    ], seconds: 60),
    'HomeFormAuth',
  );
  await _expectNone(tester, ['startTrial', 'skipAssessment']);
  expect(find.byType(TenantSetupDialog), findsNothing);
}

/// waits for the demo data dialog to go, taking its way out when the backend
/// is slow to report back
Future<void> _waitForDemoData(WidgetTester tester) async {
  for (int i = 0; i < CommonTest.demoDataWaitSeconds; i++) {
    if (!tester.any(find.byKey(const Key('setupInProgress')))) return;
    if (tester.any(find.byKey(const Key('continueWithoutDemoData')))) {
      debugPrint('demo data slow or failed, continuing without it');
      await CommonTest.tapByKey(
        tester,
        'continueWithoutDemoData',
        settle: false,
      );
      return;
    }
    await tester.pump(const Duration(seconds: 1));
  }
  fail('demo data not loaded after ${CommonTest.demoDataWaitSeconds}s');
}

/// the first of [keys] that appears within [seconds], or null
Future<String?> _waitFor(
  WidgetTester tester,
  List<String> keys, {
  int seconds = 30,
}) async {
  for (int i = 0; i < seconds * 10; i++) {
    for (final key in keys) {
      if (tester.any(find.byKey(Key(key)))) return key;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  return null;
}

Future<bool> _waitForText(
  WidgetTester tester,
  String text, {
  int seconds = 30,
}) async {
  for (int i = 0; i < seconds * 10; i++) {
    if (tester.any(find.textContaining(text))) return true;
    await tester.pump(const Duration(milliseconds: 100));
  }
  return false;
}

/// none of [keys] appears during a few seconds: the post login dialogs open a
/// frame after the dashboard
Future<void> _expectNone(
  WidgetTester tester,
  List<String> keys, {
  String? reason,
}) async {
  for (int i = 0; i < 50; i++) {
    for (final key in keys) {
      expect(find.byKey(Key(key)), findsNothing, reason: reason ?? key);
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
