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

part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  sendPassword,
  loading,
  authenticated,
  unAuthenticated,
  failure,
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
