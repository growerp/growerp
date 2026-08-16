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

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthLoad extends AuthEvent {}

class AuthUpdateLocal extends AuthEvent {
  final Authenticate authenticate;
  const AuthUpdateLocal(this.authenticate);
  @override
  List<Object> get props => [authenticate];
}

class AuthRegister extends AuthEvent {
  final User user;
  final Locale? locale;

  /// Optional caller-chosen password. When null the backend generates and
  /// emails a temporary password (the default flow).
  final String? newPassword;
  const AuthRegister(this.user, {this.locale, this.newPassword});
  @override
  List<Object> get props => [user];
}

class AuthLogin extends AuthEvent {
  final String username;
  final String password;
  // for registration continuation
  final String? companyName;
  final Currency? currency;
  final int? fiscalYearStartMonth; // accounting year start: any month 1..12
  final String? creditCardNumber;
  final String? nameOnCard;
  final String? cVC;
  final String? plan; // diyPlan, smallPlan, fullPlan
  final String? expireMonth;
  final String? expireYear;
  final bool? demoData;
  // for testing: offset backend effective time by this many days
  final int? testDaysOffset;
  const AuthLogin(
    this.username,
    this.password, {
    this.companyName,
    this.currency,
    this.fiscalYearStartMonth,
    this.demoData,
    this.creditCardNumber,
    this.nameOnCard,
    this.cVC,
    this.plan,
    this.expireMonth,
    this.expireYear,
    this.testDaysOffset,
  });
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

/// Finish a login that returned 'setupInProgress': the background demo data load
/// has ended, so the session held in state can be promoted to authenticated.
class AuthSetupCompleted extends AuthEvent {
  const AuthSetupCompleted();
}
