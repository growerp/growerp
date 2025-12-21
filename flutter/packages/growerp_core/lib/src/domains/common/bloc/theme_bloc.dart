// ignore: depend_on_referenced_packages
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeModeGet>(_onThemeModeGet);
    on<ThemeSwitch>(_onThemeSwitch);
    on<ColorSchemeChange>(_onColorSchemeChange);
  }

  Future<void> _onThemeModeGet(
    ThemeModeGet event,
    Emitter<ThemeState> emit,
  ) async {
    ThemeMode? themeMode = GlobalConfiguration().get('themeMode');
    if (themeMode == null) {
      GlobalConfiguration().addValue('themeMode', ThemeMode.light.toString());
    }
    // Load saved color scheme
    String? savedScheme = GlobalConfiguration().get('colorScheme');
    FlexScheme colorScheme = FlexScheme.jungle;
    if (savedScheme != null) {
      colorScheme = FlexScheme.values.firstWhere(
        (s) => s.name == savedScheme,
        orElse: () => FlexScheme.jungle,
      );
    }
    return emit(state.copyWith(themeMode: themeMode, colorScheme: colorScheme));
  }

  Future<void> _onThemeSwitch(
    ThemeSwitch event,
    Emitter<ThemeState> emit,
  ) async {
    GlobalConfiguration().addValue('themeMode', ThemeMode.light.toString());
    return emit(
      state.copyWith(
        themeMode: state.themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }

  Future<void> _onColorSchemeChange(
    ColorSchemeChange event,
    Emitter<ThemeState> emit,
  ) async {
    GlobalConfiguration().addValue('colorScheme', event.scheme.name);
    return emit(state.copyWith(colorScheme: event.scheme));
  }

  @override
  String toString() {
    return "ThemBloc: ${state.themeMode}, ${state.colorScheme}";
  }
}
