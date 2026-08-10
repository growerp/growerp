/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class LocaleEvent {}

class LocaleChanged extends LocaleEvent {
  final Locale locale;
  LocaleChanged(this.locale);
}

class LocaleLoaded extends LocaleEvent {}

// State
class LocaleState {
  final Locale locale;

  const LocaleState({required this.locale});

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }
}

// Bloc
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String _localeKey = 'selected_locale';

  /// The language the app is running in, for code without a build context.
  /// Sent to the backend at login, where it is saved on the user account:
  /// backend messages, emails and localized data like the GL account names
  /// resolve through it.
  static Future<String> savedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'en';
  }

  LocaleBloc() : super(const LocaleState(locale: Locale('en'))) {
    on<LocaleLoaded>(_onLocaleLoaded);
    on<LocaleChanged>(_onLocaleChanged);
  }

  void _onLocaleLoaded(LocaleLoaded event, Emitter<LocaleState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'en';
    emit(LocaleState(locale: Locale(languageCode)));
  }

  void _onLocaleChanged(LocaleChanged event, Emitter<LocaleState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, event.locale.languageCode);
    emit(LocaleState(locale: event.locale));
  }
}
