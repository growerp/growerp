/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
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
