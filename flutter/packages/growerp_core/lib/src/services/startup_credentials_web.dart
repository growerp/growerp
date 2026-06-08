/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:web/web.dart' as web;
import 'startup_credentials.dart';

const _modeKey = 'growerp_startup_mode';
const _emailKey = 'growerp_startup_email';
const _passwordKey = 'growerp_startup_password';
const _firstNameKey = 'growerp_startup_firstName';
const _lastNameKey = 'growerp_startup_lastName';

/// Reads the credentials written by the startup HTML (login or register dialog)
/// into `sessionStorage` and clears them so they are consumed exactly once.
StartupCredentials? readStartupCredentials() {
  final storage = web.window.sessionStorage;
  final mode = storage.getItem(_modeKey);
  final email = storage.getItem(_emailKey);
  if (email == null || email.isEmpty || (mode != 'login' && mode != 'register')) {
    return null;
  }
  final password = storage.getItem(_passwordKey);
  final firstName = storage.getItem(_firstNameKey);
  final lastName = storage.getItem(_lastNameKey);

  storage.removeItem(_modeKey);
  storage.removeItem(_emailKey);
  storage.removeItem(_passwordKey);
  storage.removeItem(_firstNameKey);
  storage.removeItem(_lastNameKey);

  return StartupCredentials(
    mode: mode!,
    email: email,
    password: password,
    firstName: firstName,
    lastName: lastName,
  );
}
