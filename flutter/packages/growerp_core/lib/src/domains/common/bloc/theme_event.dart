part of 'theme_bloc.dart';

@immutable
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override
  List<Object?> get props => [];
}

class ThemeSwitch extends ThemeEvent {}

class ThemeModeGet extends ThemeEvent {}
