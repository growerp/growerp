/*
 * Regression tests for the app store rejection "stuck on a black screen upon
 * launch" (freelance iOS, Aug 2026). Each test covers one of the defects that
 * produced an invisible or never ending startup state.
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup theme is light, so a blank frame is never black', () {
    // ThemeSwitch toggles; dispatching it at startup (as the bloc providers
    // used to) flipped every cold start into dark mode.
    expect(ThemeBloc().state.themeMode, ThemeMode.light);
  });

  test('getBackendUrlOverride gives up when the backend never answers', () async {
    // A socket that accepts the connection and then stays silent: this runs
    // before runApp(), so without a timeout the app never renders a frame.
    HttpOverrides.global = null; // flutter_test would answer with a 400
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <Socket>[];
    server.listen(sockets.add);

    final stopwatch = Stopwatch()..start();
    final result = await getBackendUrlOverride(
      'AppFreelance',
      '1.0.0',
      baseUrlOverride: 'http://127.0.0.1:${server.port}',
    );
    stopwatch.stop();

    expect(result.forceUpdate, isFalse);
    expect(stopwatch.elapsed, greaterThan(const Duration(seconds: 2)));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
    for (final socket in sockets) {
      socket.destroy();
    }
    await server.close();
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('getStartupCompany gives up when the backend never answers', () async {
    // Runs before runApp() too: an unanswered company lookup used to hold the
    // app on an empty window for as long as the dio receive timeout allowed.
    // flutter_test answers every http request with a 400 by default, which
    // would hide the hang this test is about.
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    GlobalConfiguration().loadFromMap({'singleCompany': ''});
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    // hold the accepted sockets: a dropped reference closes the connection and
    // the request would fail fast instead of hanging
    final sockets = <Socket>[];
    server.listen(sockets.add);

    final restClient = RestClient(
      Dio()
        ..options = BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}/')
        ..options.receiveTimeout = const Duration(minutes: 5),
    );

    final stopwatch = Stopwatch()..start();
    final company = await getStartupCompany(
      restClient,
      args: ['--companyPartyId=100000'],
    );
    stopwatch.stop();

    expect(company, isNull);
    // the request really did hang: it was cut off by the timeout, well before
    // the 5 minute dio receive timeout above
    expect(stopwatch.elapsed, greaterThan(const Duration(seconds: 2)));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
    for (final socket in sockets) {
      socket.destroy();
    }
    await server.close();
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('AppLoadingScreen shows visible progress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLoadingScreen())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('appLoadingScreen')), findsOneWidget);
  });

  testWidgets('AppLoadingScreen offers a retry when the wait drags on', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppLoadingScreen(
            retryDelay: const Duration(milliseconds: 50),
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('retryStartup')), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const Key('retryStartup')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retryStartup')));
    await tester.pump();
    expect(retries, 1);
    // the button hides again while the retry runs
    expect(find.byKey(const Key('retryStartup')), findsNothing);
  });

  testWidgets('StartupErrorScreen offers a retry when one is given', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      StartupErrorScreen(message: 'boom', onRetry: () => retries++),
    );
    await tester.tap(find.byKey(const Key('retryStartup')));
    expect(retries, 1);
  });

  testWidgets('StartupErrorScreen shows the failure instead of a blank window', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupErrorScreen(message: 'boom'));
    expect(find.text('boom'), findsOneWidget);
  });
}
