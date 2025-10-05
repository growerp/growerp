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

import '../../../l10n/generated/user_company_localizations.dart';

/// Translates User BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'userUpdateSuccess:John Doe' -> "User John Doe updated successfully"
///
/// Usage in BlocListener:
/// ```dart
/// BlocListener<UserBloc, UserState>(
///   listener: (context, state) {
///     if (state.message != null) {
///       final localizations = UserCompanyLocalizations.of(context)!;
///       final translatedMessage = translateUserBlocMessage(localizations, state.message!);
///
///       HelperFunctions.showMessage(
///         context,
///         translatedMessage,
///         state.status == UserStatus.success ? Colors.green : Colors.red,
///       );
///     }
///   },
///   child: // ... your UI
/// )
/// ```
String translateUserBlocMessage(
  UserCompanyLocalizations l10n,
  String messageKey,
) {
  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'userUpdateSuccess':
        return l10n.userUpdateSuccess(param);
      case 'userDeleteSuccess':
        return l10n.userDeleteSuccess(param);
      case 'userAddSuccess':
        return l10n.userAddSuccess(param);
      default:
        break;
    }
  }

  // Handle non-parameterized messages
  switch (messageKey) {
    case 'userUpdateFailure':
      return l10n.userUpdateFailure;
    case 'userDeleteFailure':
      return l10n.userDeleteFailure;
    case 'userAddFailure':
      return l10n.userAddFailure;
    case 'userFetchFailure':
      return l10n.userFetchFailure;
    case 'userValidationError':
      return l10n.userValidationError;

    // Fallback: return the key itself if no translation found
    default:
      return messageKey;
  }
}

/// Translates Company BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
String translateCompanyBlocMessage(
  UserCompanyLocalizations l10n,
  String messageKey,
) {
  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'companyUpdateSuccess':
        return l10n.companyUpdateSuccess(param);
      case 'companyAddSuccess':
        return l10n.companyAddSuccess(param);
      default:
        break;
    }
  }

  // Handle non-parameterized messages
  switch (messageKey) {
    case 'companyUpdateFailure':
      return l10n.companyUpdateFailure;
    case 'companyDeleteSuccess':
      return l10n.companyDeleteSuccess;
    case 'companyDeleteFailure':
      return l10n.companyDeleteFailure;
    case 'companyAddFailure':
      return l10n.companyAddFailure;
    case 'companyFetchFailure':
      return l10n.companyFetchFailure;

    // Fallback
    default:
      return messageKey;
  }
}

/// Translates CompanyUser BLoC message keys to localized strings
String translateCompanyUserBlocMessage(
  UserCompanyLocalizations l10n,
  String messageKey,
) {
  switch (messageKey) {
    // CompanyUser operations
    case 'compUserUploadSuccess':
      return l10n.compUserUploadSuccess;
    case 'compUserUploadFailure':
      return l10n.compUserUploadFailure;
    case 'compUserDownloadSuccess':
      return l10n.compUserDownloadSuccess;
    case 'compUserDownloadFailure':
      return l10n.compUserDownloadFailure;

    // Fallback
    default:
      return messageKey;
  }
}

/// Generic translator for all user_company package BLoC messages
///
/// This is a convenience function that tries all message types.
/// For better performance in production, use the specific translator functions.
String translateUserCompanyBlocMessage(
  UserCompanyLocalizations l10n,
  String messageKey,
) {
  // Try user messages first
  final userMessage = translateUserBlocMessage(l10n, messageKey);
  if (userMessage != messageKey) return userMessage;

  // Try company messages
  final companyMessage = translateCompanyBlocMessage(l10n, messageKey);
  if (companyMessage != messageKey) return companyMessage;

  // Try company-user messages
  final companyUserMessage = translateCompanyUserBlocMessage(l10n, messageKey);
  if (companyUserMessage != messageKey) return companyUserMessage;

  // Fallback to the original key
  return messageKey;
}
