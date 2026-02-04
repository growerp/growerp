import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

const FlexSchemeData growerpPremium = FlexSchemeData(
  name: 'GrowERP Premium',
  description: 'Premium emerald and teal theme for GrowERP',
  light: FlexSchemeColor(
    primary: Color(0xFF006B5A),
    primaryContainer: Color(0xFF63FADB),
    secondary: Color(0xFF006C53),
    secondaryContainer: Color(0xFF81F8D0),
    tertiary: Color(0xFF426278),
    tertiaryContainer: Color(0xFFC7E7FF),
    appBarColor: Color(0xFF006C53),
    error: Color(0xFFBA1A1A),
  ),
  dark: FlexSchemeColor(
    primary: Color(0xFF3EDDBF),
    primaryContainer: Color(0xFF005144),
    secondary: Color(0xFF64DBB4),
    secondaryContainer: Color(0xFF00513E),
    tertiary: Color(0xFFAACBE4),
    tertiaryContainer: Color(0xFF2A4A5F),
    appBarColor: Color(0xFF005144),
    error: Color(0xFFFFB4AB),
  ),
);

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF006B5A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF63FADB),
  onPrimaryContainer: Color(0xFF00201A),
  secondary: Color(0xFF006C53),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFF81F8D0),
  onSecondaryContainer: Color(0xFF002117),
  tertiary: Color(0xFF426278),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFC7E7FF),
  onTertiaryContainer: Color(0xFF001E2E),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFAFDFA),
  onSurface: Color(0xFF191C1B),
  surfaceContainerHighest: Color(0xFFDBE5E0),
  onSurfaceVariant: Color(0xFF3F4946),
  outline: Color(0xFF6F7975),
  onInverseSurface: Color(0xFFEFF1EF),
  inverseSurface: Color(0xFF2E3130),
  inversePrimary: Color(0xFF3EDDBF),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF006B5A),
  outlineVariant: Color(0xFFBFC9C4),
  scrim: Color(0xFF000000),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF3EDDBF),
  onPrimary: Color(0xFF00382E),
  primaryContainer: Color(0xFF005144),
  onPrimaryContainer: Color(0xFF63FADB),
  secondary: Color(0xFF64DBB4),
  onSecondary: Color(0xFF00382A),
  secondaryContainer: Color(0xFF00513E),
  onSecondaryContainer: Color(0xFF81F8D0),
  tertiary: Color(0xFFAACBE4),
  onTertiary: Color(0xFF113447),
  tertiaryContainer: Color(0xFF2A4A5F),
  onTertiaryContainer: Color(0xFFC7E7FF),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF191C1B),
  onSurface: Color(0xFFE0E3E0),
  surfaceContainerHighest: Color(0xFF3F4946),
  onSurfaceVariant: Color(0xFFBFC9C4),
  outline: Color(0xFF89938F),
  onInverseSurface: Color(0xFF191C1B),
  inverseSurface: Color(0xFFE0E3E0),
  inversePrimary: Color(0xFF006B5A),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF3EDDBF),
  outlineVariant: Color(0xFF3F4946),
  scrim: Color(0xFF000000),
);

// =============================================================================
// Semantic Colors for Status Indicators
// =============================================================================

/// Semantic color tokens for status indicators throughout the app.
/// Use these colors for consistent meaning across all screens.
class SemanticColors {
  // Light mode semantic colors
  static const Color successLight = Color(0xFF10B981);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color dangerLight = Color(0xFFEF4444);
  static const Color infoLight = Color(0xFF3B82F6);

  // Dark mode semantic colors
  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color dangerDark = Color(0xFFF87171);
  static const Color infoDark = Color(0xFF60A5FA);

  // On-colors (text/icons on semantic backgrounds)
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onWarning = Color(0xFF000000);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color onInfo = Color(0xFFFFFFFF);

  /// Get the appropriate semantic color based on brightness
  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? successDark : successLight;

  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark ? warningDark : warningLight;

  static Color danger(Brightness brightness) =>
      brightness == Brightness.dark ? dangerDark : dangerLight;

  static Color info(Brightness brightness) =>
      brightness == Brightness.dark ? infoDark : infoLight;
}

/// Extension on ColorScheme to provide semantic colors
extension SemanticColorScheme on ColorScheme {
  /// Success color - for completed, paid, shipped states
  Color get success => SemanticColors.success(brightness);

  /// Warning color - for pending, attention needed states
  Color get warning => SemanticColors.warning(brightness);

  /// Danger color - for overdue, cancelled, error states
  Color get danger => SemanticColors.danger(brightness);

  /// Info color - for informational, in-progress states
  Color get info => SemanticColors.info(brightness);

  /// Text color on success background
  Color get onSuccess => SemanticColors.onSuccess;

  /// Text color on warning background
  Color get onWarning => SemanticColors.onWarning;

  /// Text color on danger background
  Color get onDanger => SemanticColors.onDanger;

  /// Text color on info background
  Color get onInfo => SemanticColors.onInfo;
}
