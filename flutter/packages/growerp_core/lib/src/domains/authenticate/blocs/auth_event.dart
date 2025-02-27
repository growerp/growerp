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

class AuthUpdateLocal extends AuthEvent {
  final Authenticate? authenticate;
  final String? addNotReadChatRoom;
  final String? delNotReadChatRoom;
  const AuthUpdateLocal(
      {this.authenticate, this.addNotReadChatRoom, this.delNotReadChatRoom});

  @override
  String toString() =>
      "AuthUpdateLocal: add local add room: $addNotReadChatRoom del: $delNotReadChatRoom";
}

class AuthRegister extends AuthEvent {
  final User user;
  const AuthRegister(this.user);
  @override
  List<Object> get props => [user];
}

class AuthLogin extends AuthEvent {
  final String username;
  final String password;
  // for registration continuation
  final bool extraInfo;
  final String? companyName;
  final Currency? currency;
  final bool? demoData;
  const AuthLogin(this.username, this.password,
      {this.extraInfo = false, this.companyName, this.currency, this.demoData});
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
