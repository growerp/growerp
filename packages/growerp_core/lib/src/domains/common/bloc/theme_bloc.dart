// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeModeGet>(_onThemeModeGet);
    on<ThemeSwitch>(_onThemeSwitch);
  }

  Future<void> _onThemeModeGet(event, emit) async {
    ThemeMode? themeMode = GlobalConfiguration().get('themeMode');
    debugPrint("===get themeMode: $themeMode");
    if (themeMode == null) {
      GlobalConfiguration().addValue('themeMode', ThemeMode.light.toString());
    }
    return emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> _onThemeSwitch(event, emit) async {
    GlobalConfiguration().addValue('themeMode', ThemeMode.light.toString());
    return emit(state.copyWith(
        themeMode: state.themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light));
  }

  @override
  String toString() {
    return "ThemBloc: ${state.themeMode}";
  }
}
