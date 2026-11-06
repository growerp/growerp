import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';
import 'package:growerp_core/src/domains/common/bloc/locale_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic locale persists and is restored', () async {
    SharedPreferences.setMockInitialValues({});
    final bloc = LocaleBloc();
    final changed = bloc.stream.first;
    bloc.add(LocaleChanged(const Locale('ar')));
    expect((await changed).locale, const Locale('ar'));
    expect(await LocaleBloc.savedLanguageCode(), 'ar');
    await bloc.close();

    final restored = LocaleBloc();
    final loaded = restored.stream.first;
    restored.add(LocaleLoaded());
    expect((await loaded).locale, const Locale('ar'));
    await restored.close();
  });

  test(
    'Arabic plural forms render counts without unresolved placeholders',
    () async {
      final strings = await CoreLocalizations.delegate.load(const Locale('ar'));
      expect(strings.calendarBacklog(0), 'لا توجد منشورات بلا تاريخ');
      expect(strings.calendarBacklog(1), 'منشور واحد بلا تاريخ');
      expect(strings.calendarBacklog(2), 'منشوران بلا تاريخ');
      for (final count in [3, 11, 100]) {
        expect(strings.calendarBacklog(count), contains('$count'));
        expect(strings.calendarBacklog(count), isNot(contains('{count}')));
      }
    },
  );

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    for (final brightness in Brightness.values) {
      testWidgets('Arabic delegates and RTL at $size in $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: CoreLocalizations.supportedLocales,
            localizationsDelegates: const [
              CoreLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(brightness: brightness),
            home: Builder(
              builder: (context) {
                expect(Directionality.of(context), TextDirection.rtl);
                final strings = CoreLocalizations.of(context)!;
                expect(strings.selectLanguage, 'اختر اللغة');
                expect(strings.aboutApp('GrowERP'), contains('GrowERP'));
                return Scaffold(body: Text(strings.selectLanguage));
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('اختر اللغة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
