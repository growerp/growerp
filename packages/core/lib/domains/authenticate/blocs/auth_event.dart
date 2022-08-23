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

class AuthUserUpdate extends AuthEvent {
  final User user;
  AuthUserUpdate(this.user);
}

class AuthUpdateUser extends AuthEvent {
  final User user;
  AuthUpdateUser(this.user);
  @override
  String toString() => 'Update User: $user';
}

class AuthDeleteUser extends AuthEvent {
  final User user;
  final bool deleteCompany;
  AuthDeleteUser(this.user, this.deleteCompany);
  @override
  String toString() => 'Delete User: $user Company: $deleteCompany';
}

class AuthUpdateCompany extends AuthEvent {
  final Company? company;
  AuthUpdateCompany(this.company);
  @override
  String toString() => 'Update Company $company';
}

class AuthRegisterCompanyAndAdmin extends AuthEvent {
  final User user;
  final String currencyId;
  final bool demoData;
  AuthRegisterCompanyAndAdmin(this.user, this.currencyId,
      [this.demoData = true]);
  @override
  String toString() => 'Register Company Admin User: $user';
}

class AuthRegisterUserEcommerce extends AuthEvent {
  final User user;
  AuthRegisterUserEcommerce(this.user);
  @override
  String toString() => 'Register Customer User: $user';
}

class AuthLogin extends AuthEvent {
  final Company? company;
  final String username;
  final String password;
  const AuthLogin(this.company, this.username, this.password);
  @override
  String toString() => 'Auth Logged in with $company and $username';
}

class AuthResetPassword extends AuthEvent {
  final String username;
  const AuthResetPassword({required this.username});
  @override
  String toString() => 'ResetPassword with $username';
}

class AuthChangePassword extends AuthEvent {
  final String username;
  final String oldPassword;
  final String newPassword;
  const AuthChangePassword(this.username, this.oldPassword, this.newPassword);
  @override
  String toString() => 'Change Password with $username';
}

class AuthLoggedOut extends AuthEvent {
  final Authenticate? authenticate;
  const AuthLoggedOut({this.authenticate});
  @override
  String toString() => 'loggedOut with: ${authenticate?.user?.loginName}';
}
