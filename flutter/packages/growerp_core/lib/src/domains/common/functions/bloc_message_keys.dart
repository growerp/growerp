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

/// Message keys for Auth BLoC
class AuthBlocMessageKeys {
  static const String loginSuccess = 'authLoginSuccess';
  static const String loginFailure = 'authLoginFailure';
  static const String logoutSuccess = 'authLogoutSuccess';
  static const String registerSuccess = 'authRegisterSuccess';
  static const String registerFailure = 'authRegisterFailure';
  static const String passwordResetSuccess = 'authPasswordResetSuccess';
  static const String passwordResetFailure = 'authPasswordResetFailure';
  static const String updateSuccess = 'authUpdateSuccess';
  static const String updateFailure = 'authUpdateFailure';

  const AuthBlocMessageKeys._();
}

/// Message keys for Notification BLoC
class NotificationBlocMessageKeys {
  static const String fetchSuccess = 'notificationFetchSuccess';
  static const String fetchFailure = 'notificationFetchFailure';
  static const String markReadSuccess = 'notificationMarkReadSuccess';
  static const String markReadFailure = 'notificationMarkReadFailure';

  const NotificationBlocMessageKeys._();
}
