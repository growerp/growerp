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
  loading,
  authenticated,
  unAuthenticated,
  failure,
  changeIp,
  passwordChange,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.authenticate,
    this.message,
  });

  final AuthStatus status;
  final Authenticate? authenticate;
  final String? message;

  AuthState copyWith({
    AuthStatus? status,
    Authenticate? authenticate,
    String? message,
  }) {
    return AuthState(
      status: status ?? this.status,
      authenticate: authenticate ?? this.authenticate,
      message: message, // message not kept over state changes
    );
  }

  @override
  List<Object?> get props => [status, authenticate, message];

  @override
  String toString() => "$status { company: ${authenticate?.company} "
      "user: ${authenticate?.user} "
      "ApiKey: ${authenticate?.apiKey?.substring(0, 10)}....";
}
