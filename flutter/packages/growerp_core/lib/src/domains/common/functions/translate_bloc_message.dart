/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

/// Translates a BLoC message key to a localized string using the provided localizations object.
///
/// This function provides a clean separation between BLoC (business logic) and UI (localization).
/// BLoCs emit message keys, and the UI layer translates them using this helper.
///
/// Usage:
/// ```dart
/// BlocListener<UserBloc, UserState>(
///   listener: (context, state) {
///     if (state.status == UserStatus.success && state.message != null) {
///       final localizations = UserCompanyLocalizations.of(context)!;
///       HelperFunctions.showMessage(
///         context,
///         translateBlocMessage(localizations, state.message!),
///         Colors.green,
///       );
///     }
///   },
///   child: // ... your UI
/// )
/// ```
///
/// Parameters:
/// - [localizations]: The localizations object (e.g., UserCompanyLocalizations, CoreLocalizations)
/// - [messageKey]: The message key to translate (e.g., 'userUpdateSuccess')
/// - [params]: Optional map of parameters to replace in the translated message
///
/// Returns: The translated string, or the original key if no translation is found
String translateBlocMessage(
  dynamic localizations,
  String messageKey, {
  Map<String, dynamic>? params,
}) {
  try {
    // Use a type-safe approach without using mirrors
    String? translatedMessage = _getTranslationFromLocalizations(
      localizations,
      messageKey,
      params,
    );

    return translatedMessage ?? messageKey;
  } catch (e) {
    debugPrint('Translation error for key "$messageKey": $e');
    return messageKey; // Fallback to the key itself
  }
}

/// Internal helper to get translation from localizations object
String? _getTranslationFromLocalizations(
  dynamic localizations,
  String messageKey,
  Map<String, dynamic>? params,
) {
  // Try to call the method on the localizations object
  // We need to handle this carefully without dart:mirrors

  // For now, return null to indicate we should use a different approach
  // The actual implementation will depend on having access to the localizations
  // methods directly in the UI layer
  return null;
}

/// Helper function to translate BLoC messages in the UI layer with type-safe localizations
///
/// This is the recommended approach: pass the localizations object that has
/// the specific method for the message key.
///
/// Example:
/// ```dart
/// final localizations = UserCompanyLocalizations.of(context)!;
/// final message = translateBlocMessageTyped(
///   messageKey: state.message!,
///   translator: (key) {
///     switch (key) {
///       case 'userUpdateSuccess': return localizations.userUpdateSuccess;
///       case 'userUpdateFailure': return localizations.userUpdateFailure;
///       case 'userDeleteSuccess': return localizations.userDeleteSuccess;
///       default: return key;
///     }
///   },
/// );
/// ```
String translateBlocMessageTyped({
  required String messageKey,
  required String Function(String) translator,
}) {
  try {
    return translator(messageKey);
  } catch (e) {
    debugPrint('Translation error for key "$messageKey": $e');
    return messageKey;
  }
}

/// Base class for creating message key constants to avoid magic strings
///
/// Usage:
/// ```dart
/// class UserBlocMessageKeys {
///   static const String updateSuccess = 'userUpdateSuccess';
///   static const String updateFailure = 'userUpdateFailure';
///   static const String deleteSuccess = 'userDeleteSuccess';
///   static const String deleteFailure = 'userDeleteFailure';
/// }
/// ```
abstract class BlocMessageKeys {
  const BlocMessageKeys();
}
