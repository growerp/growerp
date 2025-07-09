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
  final String? companyName;
  final Currency? currency;
  final String? creditCardNumber;
  final String? nameOnCard;
  final String? cVC;
  final String? plan; // diyPlan, smallPlan, fullPlan
  final String? expireMonth;
  final String? expireYear;
  final bool? demoData;
  const AuthLogin(this.username, this.password,
      {this.companyName,
      this.currency,
      this.demoData,
      this.creditCardNumber,
      this.nameOnCard,
      this.cVC,
      this.plan,
      this.expireMonth,
      this.expireYear});
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
}
