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
import 'dart:io' show Platform;
import 'package:ecommerce/blocs/@blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/@models.dart';

/// Authbloc controls the connection to the backend
///
/// It contains company and user information and signals connection errrors,
/// keeps the token and apiKey in the [Authenticate] class.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final repos;
  final CatalogBloc catalogBloc;
  final CrmBloc crmBloc;
  Authenticate authenticate;

  AuthBloc(this.repos, this.catalogBloc, this.crmBloc)
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
        //print("===15==3==");
        authenticate = null;
        await repos.persistAuthenticate(authenticate);
      }
    }

    Future<AuthState> checkApikey() async {
      //print("===10==== apiKey: ${authenticate?.apiKey}");
      if (authenticate?.apiKey == null) {
        if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))
          catalogBloc.add(LoadCatalog(authenticate.company.partyId));
        return AuthUnauthenticated(authenticate);
      } else {
        repos.setApikey(authenticate?.apiKey);
        dynamic result = await repos.checkApikey();
        if (result is bool && result) {
          //print("===11====");
          if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
            //ignore when test
            catalogBloc.add(LoadCatalog(authenticate.company.partyId));
            crmBloc.add(LoadCrm(authenticate.company.partyId));
          }
          return AuthAuthenticated(authenticate);
        } else {
          print("===12====");
          authenticate.apiKey = null; // revoked
          repos.setApikey(null);
          print("===13====");
          await repos.persistAuthenticate(authenticate);
          if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))
            catalogBloc.add(LoadCatalog(authenticate.company.partyId));
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
        yield AuthProblem(connected);
      } else {
        authenticate = await repos.getAuthenticate();
        if (authenticate?.company?.partyId != null) {
          //print("===1====${authenticate.apiKey}");
          // check company
          dynamic result =
              await repos.checkCompany(authenticate.company.partyId);
          if (result == false) await findDefaultCompany();
          //print("===2====company: ${authenticate?.company?.partyId}");
          // now check user apiKey
          yield await checkApikey();
        } else {
          //print("===3====${authenticate?.apiKey}");
          await findDefaultCompany();
          // only load crmbloc when logged in
          yield await checkApikey();
        }
      }
    } else if (event is LoggedIn) {
      yield AuthLoading();
      await repos.persistAuthenticate(event.authenticate);
      authenticate = event.authenticate;
      // only load crmbloc when logged in
      if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
        catalogBloc.add(LoadCatalog(authenticate.company.partyId));
        crmBloc.add(LoadCrm(authenticate.company.partyId));
      }
      yield AuthAuthenticated(authenticate, "Successfully logged in");
    } else if (event is Logout) {
      yield AuthLoading();
      authenticate = await repos.logout();
      yield AuthUnauthenticated(authenticate, "you are logged out now");
    } else if (event is ResetPassword) {
      await repos.resetPassword(username: event.username);
    } else if (event is UpdateAuth) {
      authenticate = await repos.logout();
      yield AuthLoading();
      await repos.persistAuthenticate(authenticate);
      yield AuthUnauthenticated(authenticate);
    } else if (event is UpdateCompany) {
      yield AuthLoading();
      dynamic result =
          await repos.updateCompany(event.company, event.imagePath);
      if (result is Company) {
        authenticate.company = result;
        yield AuthAuthenticated(authenticate, 'Company updated');
      } else {
        yield AuthProblem(result, event.company);
      }
    } else if (event is UpdateEmployee) {
      yield AuthLoading((event.user?.partyId == null ? "Adding " : "Updating") +
          " user ${event.user}");
      dynamic result = await repos.updateUser(event.user, event.imagePath);
      if (result is User) {
        if (event.user.partyId == result.partyId) authenticate.user = result;
        List<User> users = authenticate.company.employees;
        if (event.user.partyId == null)
          users.add(result);
        else {
          // update
          int index =
              users.indexWhere((user) => user.partyId == result.partyId);
          users.replaceRange(index, index + 1, [result]);
        }
        await repos.persistAuthenticate(authenticate);
        yield AuthAuthenticated(authenticate,
            'User ' + (event.user?.partyId == null ? 'Added' : 'Updated'));
      } else {
        yield AuthProblem(result, null, event.user);
      }
    } else if (event is DeleteEmployee) {
      yield AuthLoading("Deleting user ${event.user}");
      dynamic result = await repos.deleteUser(event.user.partyId);
      if (result == event.user.partyId) {
        List users = authenticate.company.employees;
        int index = users.indexWhere((user) => user.partyId == result);
        users.removeAt(index);
        await repos.persistAuthenticate(authenticate);
        yield AuthAuthenticated(authenticate, 'User ${event.user} deleted');
      } else {
        yield AuthProblem(result);
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
  final Authenticate authenticate;
  UpdateAuth(this.authenticate);
  @override
  String toString() => 'Update Authenticate ${authenticate.toString()}';
}

class UpdateCompany extends AuthEvent {
  final Authenticate authenticate;
  final Company company;
  final String imagePath;
  UpdateCompany(this.authenticate, this.company, this.imagePath);
  @override
  String toString() => 'Update Company ${authenticate.company.toString()} '
      'new image: ${imagePath != null ? imagePath.length : 0}';
}

class UpdateEmployee extends AuthEvent {
  final User user;
  final String imagePath;
  UpdateEmployee(this.user, this.imagePath);
  @override
  String toString() => (user?.partyId == null ? 'Add' : 'Update') + '$user';
}

class DeleteEmployee extends AuthEvent {
  final User user;
  DeleteEmployee(this.user);
  @override
  String toString() => 'Update User $user';
}

class LoggedIn extends AuthEvent {
  final Authenticate authenticate;
  const LoggedIn({@required this.authenticate});
  @override
  String toString() => 'Auth Logged in with ${authenticate.user}';
}

class ResetPassword extends AuthEvent {
  final String username;
  const ResetPassword({@required this.username});
  @override
  String toString() => 'ResetPassword with $username';
}

class LoggingOut extends AuthEvent {
  final Authenticate authenticate;
  const LoggingOut({this.authenticate});
  @override
  String toString() => 'loggedOut with: ${authenticate?.user?.name}';
}

class UploadImage extends AuthEvent {
  final String partyId;
  final String fileName;
  UploadImage(this.partyId, this.fileName);
  String toString() => "Upload User $partyId image at $fileName]";
}

// ################## state ###################
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String message;
  AuthLoading([this.message]);
  String toString() => 'Authloading msg: $message';
}

class AuthProblem extends AuthState {
  final String errorMessage;
  final Company newCompany;
  final User newUser;
  AuthProblem(this.errorMessage, [this.newCompany, this.newUser]);
  @override
  String toString() => 'AuthProblem: errorMessage: $errorMessage';
}

class AuthAuthenticated extends AuthState {
  final Authenticate authenticate;
  final String message;
  AuthAuthenticated(this.authenticate, [this.message]);
  @override
  String toString() => 'Authenticated: Msg: $message $authenticate}';
}

class AuthUnauthenticated extends AuthState {
  final Authenticate authenticate;
  final String message;
  AuthUnauthenticated(this.authenticate, [this.message]);
  @override
  String toString() => 'Unauthenticated: msg: $message $authenticate';
}
