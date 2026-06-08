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

part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  sendPassword,
  loading,
  authenticated,
  unAuthenticated,
  failure,
  changeIp,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.authenticate,
    this.message,
    this.pendingRegistrationEmail,
    this.pendingRegistrationPassword,
  });

  final AuthStatus status;
  final Authenticate? authenticate;
  final String? message;

  /// When set (web startup page found no existing account), the unauthenticated
  /// landing auto-opens the registration dialog prefilled with this email.
  /// Transient: not carried across state changes (consumed once).
  final String? pendingRegistrationEmail;

  /// Password typed on the web startup page, used as the new account's password
  /// when finishing registration. Transient, consumed once.
  final String? pendingRegistrationPassword;

  AuthState copyWith({
    AuthStatus? status,
    Authenticate? authenticate,
    String? message,
    String? pendingRegistrationEmail,
    String? pendingRegistrationPassword,
  }) {
    return AuthState(
      status: status ?? this.status,
      authenticate: authenticate ?? this.authenticate,
      message: message, // message not kept over state changes
      pendingRegistrationEmail:
          pendingRegistrationEmail, // transient, consumed once
      pendingRegistrationPassword:
          pendingRegistrationPassword, // transient, consumed once
    );
  }

  @override
  List<Object?> get props => [
    status,
    authenticate,
    message,
    pendingRegistrationEmail,
    pendingRegistrationPassword,
  ];

  @override
  String toString() =>
      "$status { owner: ${authenticate?.ownerPartyId} company: ${authenticate?.company?.name} "
      "user: ${authenticate?.user?.lastName ?? '?'} "
      //    "ApiKey: ${authenticate?.apiKey?.substring(0, 10)}...."
      " message: $message";
}
