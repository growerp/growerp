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
import '../../../api_repository.dart';
import '../../common/functions/functions.dart';
import '../../../services/api_result.dart';
import '../../../services/chat_server.dart';
import '../../../services/network_exceptions.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domains/domains.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Authbloc controls the connection to the backend
///
/// It contains company and user information and signals connection errrors,
/// keeps the token and apiKey in the [Authenticate] class.
///
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repos, this.chat) : super(const AuthState()) {
    on<AuthLoad>(_onAuthLoad);
    on<AuthUserUpdate>(_onAuthUserUpdate);
    on<AuthUpdateCompany>(_onAuthUpdateCompany);
    on<AuthUpdateUser>(_onAuthUpdateUser);
    on<AuthDeleteUser>(_onAuthDeleteUser);
    on<AuthRegisterCompanyAndAdmin>(_onAuthRegisterCompanyAndAdmin);
    on<AuthRegisterUserEcommerce>(_onAuthRegisterUserEcommerce);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthLogin>(_onAuthLogin);
    on<AuthResetPassword>(_onAuthResetPassword);
    on<AuthChangePassword>(_onAuthChangePassword);
  }

  final APIRepository repos;
  final ChatServer chat;

  Future<void> _onAuthUserUpdate(
    AuthUserUpdate event,
    Emitter<AuthState> emit,
  ) async {
    return emit(state.copyWith(
        authenticate: state.authenticate!.copyWith(user: event.user)));
  }

  Future<void> _onAuthLoad(
    AuthLoad event,
    Emitter<AuthState> emit,
  ) async {
    // test connection and get session token
    ApiResult<dynamic> connectResult = await repos.getConnected();
    var connect = connectResult.when(
        success: (data) => data,
        failure: (NetworkExceptions error) => error.toString());
    if (connect is String) return emit(// no connection
          state.copyWith(status: AuthStatus.failure, message: connect));
    // get default company
    ApiResult<List<Company>> defResult = await repos.getCompanies(limit: 1);
    Company defaultCompany = defResult.when(
        success: (List<Company> data) => data.isNotEmpty ? data[0] : Company(),
        failure: (_) => Company());
    // get session data from last time
    var localAuthenticate = await PersistFunctions.getAuthenticate();
    if (localAuthenticate != null &&
        localAuthenticate.apiKey != null &&
        localAuthenticate.company?.partyId != null) {
      // check if company still valid
      ApiResult<bool> checkResult =
          await repos.checkCompany(localAuthenticate.company!.partyId!);
      bool ok = (checkResult.when(
          success: (bool data) => data, failure: (_) => false));
      if (!ok)
        return emit(state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: Authenticate(company: defaultCompany)));
      // test apiKey and get Authenticate
      repos.setApiKey(
          localAuthenticate.apiKey!, localAuthenticate.moquiSessionToken!);
      ApiResult<Authenticate> authResult = await repos.getAuthenticate();
      emit(authResult.when(
          success: (Authenticate data) => state.copyWith(
              status: AuthStatus.authenticated, authenticate: data),
          failure: (_) => state.copyWith(
              status: AuthStatus.unAuthenticated,
              authenticate: Authenticate(company: localAuthenticate.company))));
      if (state.status == AuthStatus.authenticated) {
        await PersistFunctions.persistAuthenticate(state.authenticate!);
        repos.setApiKey(state.authenticate!.apiKey!,
            state.authenticate!.moquiSessionToken!);
        chat.connect(
            state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
      }
    } else {
      await PersistFunctions.persistAuthenticate(
          Authenticate(company: defaultCompany));
      emit(state.copyWith(
          status: AuthStatus.unAuthenticated,
          authenticate: Authenticate(company: defaultCompany)));
    }
  }

  Future<void> _onAuthUpdateCompany(
    AuthUpdateCompany event,
    Emitter<AuthState> emit,
  ) async {
    if (event.company?.partyId == state.authenticate?.company?.partyId) {
      //only update owner company
      ApiResult<Company> compResult = await repos.updateCompany(event.company!);
      emit(state.copyWith(status: AuthStatus.loading));
      return emit(compResult.when(
          success: (data) {
            return state.copyWith(
                authenticate: state.authenticate?.copyWith(company: data),
                status: AuthStatus.authenticated,
                message: 'Company ${event.company?.name} updated');
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: AuthStatus.failure, message: error.toString())));
    }
  }

  Future<void> _onAuthUpdateUser(
    AuthUpdateUser event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user.partyId == state.authenticate?.user!.partyId) {
      //only update owner company
      ApiResult<User> compResult = await repos.updateUser(event.user);
      return emit(compResult.when(
          success: (data) {
            return state.copyWith(
                authenticate: state.authenticate?.copyWith(user: data),
                message:
                    'User ${event.user.firstName} ${event.user.lastName} updated');
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: AuthStatus.failure, message: error.toString())));
    }
  }

  Future<void> _onAuthDeleteUser(
    AuthDeleteUser event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user.partyId == state.authenticate?.user!.partyId) {
      //only delete logged in user
      ApiResult<User> compResult =
          await repos.deleteUser(event.user.partyId!, event.deleteCompany);
      return emit(compResult.when(
          success: (data) {
            return state.copyWith(
                authenticate: Authenticate(),
                message:
                    'User ${event.user.firstName} ${event.user.lastName} deleted');
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: AuthStatus.failure, message: error.toString())));
    }
  }

  Future<void> _onAuthRegisterCompanyAndAdmin(
    AuthRegisterCompanyAndAdmin event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    ApiResult<Authenticate> apiResult = await repos.register(
        companyName: event.user.companyName!,
        currencyId: event.currencyId,
        firstName: event.user.firstName!,
        lastName: event.user.lastName!,
        email: event.user.email!,
        demoData: event.demoData);
    emit(apiResult.when(
        success: (Authenticate data) {
          emit(state.copyWith(status: AuthStatus.registered));
          return state.copyWith(
              status: AuthStatus.unAuthenticated,
              authenticate: data,
              message: '     Register Company and Admin successful,\n'
                  ' you can now login with the password sent by email');
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: AuthStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
    if (state.status == AuthStatus.unAuthenticated)
      await PersistFunctions.persistAuthenticate(state.authenticate!);
  }

  Future<void> _onAuthRegisterUserEcommerce(
    AuthRegisterUserEcommerce event,
    Emitter<AuthState> emit,
  ) async {
    ApiResult<User> apiResult = await repos.registerUser(
        event.user.copyWith(userGroup: UserGroup.Customer),
        state.authenticate!.company!.partyId!);
    emit(apiResult.when(
        success: (User data) {
          emit(state.copyWith(status: AuthStatus.registered));
          return state.copyWith(
              status: AuthStatus.unAuthenticated,
              message: '          Register successful,\n'
                  'you can now login with the password sent by email.',
              authenticate: state.authenticate!.copyWith(user: data));
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: AuthStatus.failure, message: error.toString())));
    if (state.status == AuthStatus.registered)
      await PersistFunctions.persistAuthenticate(state.authenticate!);
  }

  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    ApiResult<String> apiResult = await repos.logout();
    emit(apiResult.when(
        success: (data) => state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: state.authenticate!.copyWith(apiKey: null),
            message: "you are logged out now"),
        failure: (NetworkExceptions error) => state.copyWith(
            status: AuthStatus.failure, message: error.toString())));
    if (state.status == AuthStatus.unAuthenticated)
      await PersistFunctions.persistAuthenticate(
          state.authenticate!.copyWith(apiKey: null));
  }

  Future<void> _onAuthLogin(
    AuthLogin event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    ApiResult<Authenticate> apiResult = await repos.login(
      username: event.username,
      password: event.password,
    );
    emit(apiResult.when(
        success: (auth) {
          if (auth.apiKey == 'passwordChange')
            return state.copyWith(
                status: AuthStatus.passwordChange,
                authenticate: state.authenticate,
                message: 'need to change password');
          else
            return state.copyWith(
                status: AuthStatus.authenticated,
                authenticate: auth,
                message: 'You are logged in now...');
        },
        failure: (error) => state.copyWith(
            status: AuthStatus.failure,
            message: "failed logging in: ${error.toString()}")));

    if (state.status == AuthStatus.authenticated) {
      repos.setApiKey(
          state.authenticate!.apiKey!, state.authenticate!.moquiSessionToken!);
      PersistFunctions.persistAuthenticate(state.authenticate!);
      chat.connect(
          state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
    }
  }

  Future<void> _onAuthResetPassword(
    AuthResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    ApiResult<void> apiResult =
        await repos.resetPassword(username: event.username);
    emit(apiResult.when(
        success: (_) => state.copyWith(message: 'Password reset'),
        failure: (NetworkExceptions error) => state.copyWith(
            status: AuthStatus.failure, message: error.toString())));
  }

  Future<void> _onAuthChangePassword(
    AuthChangePassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    ApiResult<Authenticate> apiResult = await repos.updatePassword(
        username: event.username,
        oldPassword: event.oldPassword,
        newPassword: event.newPassword);
    emit(apiResult.when(
        success: (auth) => state.copyWith(
            message: "password successfully changed",
            status: AuthStatus.authenticated,
            authenticate: auth),
        failure: (NetworkExceptions error) => state.copyWith(
            status: AuthStatus.failure, message: error.toString())));
    if (state.status == AuthStatus.authenticated) {
      repos.setApiKey(
          state.authenticate!.apiKey!, state.authenticate!.moquiSessionToken!);
      PersistFunctions.persistAuthenticate(state.authenticate!);
      chat.connect(
          state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
    }
  }
}
