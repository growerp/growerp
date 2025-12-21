part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.colorScheme = FlexScheme.jungle,
  });

  final ThemeMode? themeMode;
  final FlexScheme colorScheme;

  ThemeState copyWith({ThemeMode? themeMode, FlexScheme? colorScheme}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }

  @override
  List<Object?> get props => [themeMode, colorScheme];
}
