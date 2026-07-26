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

import 'startup_credentials_stub.dart'
    if (dart.library.js_interop) 'startup_credentials_web.dart';

/// Credentials handed off by the web startup page (see admin/web/index.html).
///
/// The startup HTML mirrors the Flutter landing: a Login dialog collects
/// email + password (`mode == 'login'`), a Register dialog collects
/// firstName + lastName + email (`mode == 'register'`). The values are stored
/// in `sessionStorage` and read once on launch so the user is not asked again.
class StartupCredentials {
  /// Either `login` or `register`.
  final String mode;
  final String email;

  /// Login only.
  final String? password;

  /// Register only.
  final String? firstName;
  final String? lastName;

  const StartupCredentials({
    required this.mode,
    required this.email,
    this.password,
    this.firstName,
    this.lastName,
  });

  bool get isRegister => mode == 'register';
}

/// Returns the credentials supplied by the web startup page, or `null` when
/// none were supplied (always `null` on non-web platforms). The values are
/// cleared from `sessionStorage` after being read so they are consumed once.
StartupCredentials? getStartupCredentials() => readStartupCredentials();
