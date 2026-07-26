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

/// Translate ChatRoom BLoC message keys to localized strings
String translateChatRoomBlocMessage(
  String? messageKey,
  CoreLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Handle direct l10n keys (no parameters)
  if (messageKey == 'chatRoomUpdateSuccess') {
    return localizations.chatRoomUpdateSuccess;
  }
  if (messageKey == 'chatRoomAddSuccess') {
    return localizations.chatRoomAddSuccess;
  }

  // Fallback: return the key itself
  return messageKey;
}

/// Translate ChatMessage BLoC message keys to localized strings
String translateChatMessageBlocMessage(
  String? messageKey,
  CoreLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Fallback: return the key itself
  return messageKey;
}

