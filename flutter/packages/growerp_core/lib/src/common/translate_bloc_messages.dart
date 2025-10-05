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

import 'package:growerp_core/l10n/generated/core_localizations.dart';
import 'package:growerp_core/src/domains/common/functions/bloc_message_keys.dart';

/// Translate Auth BLoC message keys to localized strings
String translateAuthBlocMessage(
  String? messageKey,
  CoreLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Handle direct l10n keys with parameters
  if (messageKey.startsWith('passwordChangeSuccess:')) {
    final parts = messageKey.split(':');
    if (parts.length >= 2) {
      final username = parts[1];
      return localizations.passwordChangeSuccess(username);
    }
  }

  switch (messageKey) {
    case AuthBlocMessageKeys.loginSuccess:
      return localizations.authLoginSuccess;
    case AuthBlocMessageKeys.loginFailure:
      return localizations.authLoginFailure;
    case AuthBlocMessageKeys.logoutSuccess:
      return localizations.authLogoutSuccess;
    case AuthBlocMessageKeys.registerSuccess:
      return localizations.authRegisterSuccess;
    case AuthBlocMessageKeys.registerFailure:
      return localizations.authRegisterFailure;
    case AuthBlocMessageKeys.passwordResetSuccess:
      return localizations.authPasswordResetSuccess;
    case AuthBlocMessageKeys.passwordResetFailure:
      return localizations.authPasswordResetFailure;
    case AuthBlocMessageKeys.updateSuccess:
      return localizations.authUpdateSuccess;
    case AuthBlocMessageKeys.updateFailure:
      return localizations.authUpdateFailure;
    default:
      return messageKey;
  }
}

/// Translate Notification BLoC message keys to localized strings
String translateNotificationBlocMessage(
  String? messageKey,
  CoreLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  switch (messageKey) {
    case NotificationBlocMessageKeys.fetchSuccess:
      return localizations.notificationFetchSuccess;
    case NotificationBlocMessageKeys.fetchFailure:
      return localizations.notificationFetchFailure;
    case NotificationBlocMessageKeys.markReadSuccess:
      return localizations.notificationMarkReadSuccess;
    case NotificationBlocMessageKeys.markReadFailure:
      return localizations.notificationMarkReadFailure;
    default:
      return messageKey;
  }
}
