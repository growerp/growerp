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

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthLoad extends AuthEvent {}

class AuthMessage extends AuthEvent {
  final String message;
  const AuthMessage(this.message);
}

class AuthRegisterCompanyAndAdmin extends AuthEvent {
  final User user;
  final String currencyId;
  final bool demoData;
  const AuthRegisterCompanyAndAdmin(this.user, this.currencyId,
      [this.demoData = true]);
  @override
  List<Object> get props => [user, currencyId, demoData];
}

class AuthRegisterUserEcommerce extends AuthEvent {
  final User user;
  const AuthRegisterUserEcommerce(this.user);
}

class AuthLogin extends AuthEvent {
  final String username;
  final String password;
  const AuthLogin(this.username, this.password);
}

class AuthResetPassword extends AuthEvent {
  final String username;
  const AuthResetPassword({required this.username});
}

class AuthChangePassword extends AuthEvent {
  final String username;
  final String oldPassword;
  final String newPassword;
  const AuthChangePassword(this.username, this.oldPassword, this.newPassword);
}

class AuthLoggedOut extends AuthEvent {
  final Authenticate? authenticate;
  const AuthLoggedOut({this.authenticate});
  @override
  String toString() => 'loggedOut with: ${authenticate?.user?.loginName}';
}
