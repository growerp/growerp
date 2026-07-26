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
