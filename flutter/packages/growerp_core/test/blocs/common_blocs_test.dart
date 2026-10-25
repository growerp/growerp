import 'package:bloc_test/bloc_test.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeBloc', () {
    // loadFromMap merges: start every test from an empty configuration
    setUp(() => GlobalConfiguration().appConfig.clear());

    blocTest<ThemeBloc, ThemeState>(
      'ThemeSwitch_light_switchesToDarkAndBack',
      build: ThemeBloc.new,
      act: (bloc) => bloc
        ..add(ThemeSwitch())
        ..add(ThemeSwitch()),
      expect: () => [
        isA<ThemeState>().having((s) => s.themeMode, 'mode', ThemeMode.dark),
        isA<ThemeState>().having((s) => s.themeMode, 'mode', ThemeMode.light),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ColorSchemeChange_scheme_emitsAndStoresSchemeName',
      build: ThemeBloc.new,
      act: (bloc) => bloc.add(const ColorSchemeChange(FlexScheme.blue)),
      expect: () => [
        isA<ThemeState>().having(
          (s) => s.colorScheme,
          'colorScheme',
          FlexScheme.blue,
        ),
      ],
      verify: (_) => expect(GlobalConfiguration().get('colorScheme'), 'blue'),
    );

    blocTest<ThemeBloc, ThemeState>(
      'ThemeModeGet_savedScheme_restoresIt',
      setUp: () => GlobalConfiguration().loadFromMap({'colorScheme': 'blue'}),
      build: ThemeBloc.new,
      act: (bloc) => bloc.add(ThemeModeGet()),
      expect: () => [
        isA<ThemeState>().having(
          (s) => s.colorScheme,
          'colorScheme',
          FlexScheme.blue,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ThemeModeGet_unknownSavedScheme_fallsBackToJungle',
      setUp: () => GlobalConfiguration().loadFromMap({'colorScheme': 'nope'}),
      build: ThemeBloc.new,
      seed: () => const ThemeState(colorScheme: FlexScheme.blue),
      act: (bloc) => bloc.add(ThemeModeGet()),
      expect: () => [
        isA<ThemeState>().having(
          (s) => s.colorScheme,
          'colorScheme',
          FlexScheme.jungle,
        ),
      ],
    );
  });

  group('LocaleBloc', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    blocTest<LocaleBloc, LocaleState>(
      'LocaleLoaded_nothingSaved_usesEnglish',
      build: LocaleBloc.new,
      act: (bloc) => bloc.add(LocaleLoaded()),
      expect: () => [
        isA<LocaleState>().having(
          (s) => s.locale,
          'locale',
          const Locale('en'),
        ),
      ],
    );

    blocTest<LocaleBloc, LocaleState>(
      'LocaleChanged_thai_emitsAndPersistsForNextStart',
      build: LocaleBloc.new,
      act: (bloc) => bloc.add(LocaleChanged(const Locale('th'))),
      expect: () => [
        isA<LocaleState>().having(
          (s) => s.locale,
          'locale',
          const Locale('th'),
        ),
      ],
      verify: (_) async => expect(await LocaleBloc.savedLanguageCode(), 'th'),
    );

    blocTest<LocaleBloc, LocaleState>(
      'LocaleLoaded_savedDutch_restoresIt',
      setUp: () =>
          SharedPreferences.setMockInitialValues({'selected_locale': 'nl'}),
      build: LocaleBloc.new,
      act: (bloc) => bloc.add(LocaleLoaded()),
      expect: () => [
        isA<LocaleState>().having(
          (s) => s.locale,
          'locale',
          const Locale('nl'),
        ),
      ],
    );
  });

  group('DataFetchBloc', () {
    blocTest<DataFetchBloc<String>, DataFetchState<String>>(
      'GetDataEvent_futureCompletes_emitsLoadingThenData',
      build: DataFetchBloc<String>.new,
      act: (bloc) => bloc.add(GetDataEvent<String>(() async => 'result')),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        isA<DataFetchState<String>>().having(
          (s) => s.status,
          'status',
          DataFetchStatus.loading,
        ),
        isA<DataFetchState<String>>()
            .having((s) => s.status, 'status', DataFetchStatus.success)
            .having((s) => s.data, 'data', 'result'),
      ],
    );

    blocTest<DataFetchBloc<String>, DataFetchState<String>>(
      'GetDataEvent_futureThrowsDio_emitsFailure',
      build: DataFetchBloc<String>.new,
      act: (bloc) => bloc.add(
        GetDataEvent<String>(() async => throw dioError('Fetch failed')),
      ),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        isA<DataFetchState<String>>().having(
          (s) => s.status,
          'status',
          DataFetchStatus.loading,
        ),
        isA<DataFetchState<String>>()
            .having((s) => s.status, 'status', DataFetchStatus.failure)
            .having((s) => s.message, 'message', 'Fetch failed'),
      ],
    );
  });
}
