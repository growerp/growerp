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
