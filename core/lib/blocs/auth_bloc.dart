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

import 'dart:async';
import 'package:global_configuration/global_configuration.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:models/@models.dart';

/// Authbloc controls the connection to the backend
///
/// It contains company and user information and signals connection errrors,
/// keeps the token and apiKey in the [Authenticate] class.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final repos;
  Authenticate? authenticate;

  AuthBloc(this.repos)
      : assert(repos != null),
        super(AuthInitial());

  @override
  Stream<AuthState> mapEventToState(AuthEvent event) async* {
    // ################# local functions ###################

    Future<void> findDefaultCompany() async {
      //print("===15==1==");
      dynamic result = await repos.getCompanies();
      if (result is List<Company> && result.length > 0) {
        //print("===15==2==");
        authenticate = Authenticate(company: result[0], user: null);
        //print("======companies received: $result ");
        await repos.persistAuthenticate(authenticate);
      } else {
        // no companies yet or all removed ...
        //print("===15==3==");
        await repos.removeAuthenticate(); //clean all
      }
    }

    Future<AuthState> checkApikey() async {
      //print("===10==== apiKey: ${authenticate?.apiKey}");
      if (authenticate?.apiKey == null) {
        return AuthUnauthenticated(authenticate);
      } else {
        repos.setApikey(authenticate?.apiKey);
        dynamic result = await repos.checkApikey();
        if (result is bool && result) {
          //print("===11====");
          return AuthAuthenticated(
              authenticate, "Logged in to ${authenticate!.company!.name!}");
        } else {
          //print("===12====");
          authenticate!.apiKey = null; // revoked
          repos.setApikey('');
          //print("===13====");
          await repos.persistAuthenticate(authenticate);
          return AuthUnauthenticated(authenticate);
        }
      }
    }

    // ################# start bloc ###################
    if (event is LoadAuth) {
      //print("====start load!!!===");
      yield AuthLoading();
      dynamic connected = await repos.getConnected();
      if (connected is String) {
        String backend = GlobalConfiguration().getValue("backend");
        yield AuthProblem("$connected\nwith connector: $backend");
      } else {
        authenticate = await repos.getAuthenticate();
        if (authenticate?.company?.partyId != null) {
          //print("===1====${authenticate!.apiKey}");
          // check company
          dynamic result =
              await repos.checkCompany(authenticate!.company!.partyId);
          if (result == false) await findDefaultCompany();
          //print("===2====company: ${authenticate?.company?.partyId}");
          // now check user apiKey
          yield await checkApikey();
        } else {
          //print("===3====${authenticate?.apiKey}");
          await findDefaultCompany();
          if (authenticate?.company?.partyId != null)
            yield await checkApikey();
          else {
            //print("===4====no company found}");
            yield AuthUnauthenticated(authenticate);
          }
        }
      }
    } else if (event is LoggedIn) {
      yield AuthLoading();
      await repos.persistAuthenticate(event.authenticate);
      authenticate = event.authenticate;
      yield AuthAuthenticated(authenticate, "Successfully logged in");
    } else if (event is Logout) {
      yield AuthLoading();
      authenticate = await repos.logout(authenticate);
      yield AuthUnauthenticated(authenticate, "you are logged out now");
    } else if (event is ResetPassword) {
      await repos.resetPassword(username: event.username);
    } else if (event is UpdateCompany) {
      yield AuthLoading("Updating company....");
      dynamic result = await repos.updateCompany(event.company);
      if (result is Company) {
        authenticate?.company = result;
        yield AuthAuthenticated(authenticate, 'Company updated');
      } else {
        yield AuthProblem(result);
      }
      // add register bloc functions  register user and admin/company????
    } else if (event is RegisterCompanyAdmin) {
      yield AuthLoading();
      final dynamic authenticate = await repos.register(
          companyName: event.user.companyName,
          currencyId: event.currencyId,
          firstName: event.user.firstName,
          lastName: event.user.lastName,
          email: event.user.email);
      if (authenticate is Authenticate) {
        await repos.persistAuthenticate(authenticate);
        yield AuthRegistered();
        yield AuthUnauthenticated(
            authenticate,
            'Register Company and Admin successfull,'
            ' you can now login with your email password');
      } else {
        yield AuthProblem(authenticate);
      }
    } else if (event is RegisterUserEcommerce) {
      print("===authBloc: ${event.user} ${authenticate?.company!.partyId}");
      yield AuthLoading();
      final dynamic user = await repos.registerUser(
          event.user.copyWith(userGroupId: 'GROWERP_M_CUSTOMER'),
          authenticate?.company!.partyId);
      if (user is User) {
        authenticate?.user = user;
        await repos.persistAuthenticate(authenticate);
        yield AuthRegistered();
        yield AuthUnauthenticated(
            authenticate,
            'Register successfull,'
            ' you can now login with your email password');
      } else {
        yield AuthProblem(user);
      }
    }
  }
}

// ################# events ###################
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoadAuth extends AuthEvent {
  @override
  String toString() => 'Load AuthBoc with backend status.';
}

class Logout extends AuthEvent {}

class UpdateAuth extends AuthEvent {
  final Authenticate? authenticate;
  UpdateAuth(this.authenticate);
  @override
  String toString() => 'Update Authenticate ${authenticate.toString()}';
}

class UpdateCompany extends AuthEvent {
  final Authenticate? authenticate;
  final Company company;
  UpdateCompany(this.authenticate, this.company);
  @override
  String toString() => 'Update Company ${authenticate!.company.toString()} ';
}

class RegisterCompanyAdmin extends AuthEvent {
  final User user;
  final String currencyId;
  RegisterCompanyAdmin(this.user, this.currencyId);
  @override
  String toString() => 'Register Company Admin User: $user';
}

class RegisterUserEcommerce extends AuthEvent {
  final User user;
  RegisterUserEcommerce(this.user);
  @override
  String toString() => 'Register Customer User: $user';
}

class LoggedIn extends AuthEvent {
  final Authenticate authenticate;
  const LoggedIn({required this.authenticate});
  @override
  String toString() => 'Auth Logged in with ${authenticate.user}';
}

class ResetPassword extends AuthEvent {
  final String username;
  const ResetPassword({required this.username});
  @override
  String toString() => 'ResetPassword with $username';
}

class LoggingOut extends AuthEvent {
  final Authenticate? authenticate;
  const LoggingOut({this.authenticate});
  @override
  String toString() => 'loggedOut with: ${authenticate?.user?.name}';
}

// ################## state ###################
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthRegistered extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  AuthLoading([this.message]);
  @override
  String toString() => 'Authloading msg: $message';
}

class AuthProblem extends AuthState {
  final String? errorMessage;
  AuthProblem(this.errorMessage);
  @override
  String toString() => 'AuthProblem: errorMessage: $errorMessage';
}

class AuthAuthenticated extends AuthState {
  final Authenticate? authenticate;
  final String? message;
  AuthAuthenticated(this.authenticate, [this.message]);
  @override
  String toString() => 'Authenticated: Msg: $message $authenticate}';
}

class AuthUnauthenticated extends AuthState {
  final Authenticate? authenticate;
  final String? message;
  AuthUnauthenticated(this.authenticate, [this.message]);
  @override
  String toString() => 'Unauthenticated: msg: $message $authenticate';
}
