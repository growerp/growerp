/*
 * Regression tests for the app store rejection "stuck on a black screen upon
 * launch" (freelance iOS, Aug 2026). Each test covers one of the defects that
 * produced an invisible or never ending startup state.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

void main() {
  test('startup theme is light, so a blank frame is never black', () {
    // ThemeSwitch toggles; dispatching it at startup (as the bloc providers
    // used to) flipped every cold start into dark mode.
    expect(ThemeBloc().state.themeMode, ThemeMode.light);
  });

  test('getBackendUrlOverride gives up when the backend never answers', () async {
    // A socket that accepts the connection and then stays silent: this runs
    // before runApp(), so without a timeout the app never renders a frame.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((socket) {});

    final stopwatch = Stopwatch()..start();
    final result = await getBackendUrlOverride(
      'AppFreelance',
      '1.0.0',
      baseUrlOverride: 'http://127.0.0.1:${server.port}',
    );
    stopwatch.stop();

    expect(result.forceUpdate, isFalse);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
    await server.close();
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('AppLoadingScreen shows visible progress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLoadingScreen())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('appLoadingScreen')), findsOneWidget);
  });

  testWidgets('StartupErrorScreen shows the failure instead of a blank window', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupErrorScreen(message: 'boom'));
    expect(find.text('boom'), findsOneWidget);
  });
}
