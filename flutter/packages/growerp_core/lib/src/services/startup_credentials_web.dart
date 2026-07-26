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
