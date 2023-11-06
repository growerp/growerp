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
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive/hive.dart';

import '../../../services/chat_server.dart';
import '../../common/functions/functions.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Authbloc controls the connection to the backend
///
/// It contains company and user information and signals connection errrors,
/// keeps the token and apiKey in the [Authenticate] class.
///
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.chat, this.restClient, this.classificationId)
      : super(const AuthState()) {
    on<AuthLoad>(_onAuthLoad);
    on<AuthMessage>(_onAuthMessage);
    on<AuthRegisterCompanyAndAdmin>(_onAuthRegisterCompanyAndAdmin);
//    on<AuthRegisterUserEcommerce>(_onAuthRegisterUserEcommerce);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthLogin>(_onAuthLogin);
    on<AuthResetPassword>(_onAuthResetPassword);
    on<AuthChangePassword>(_onAuthChangePassword);
  }

  final RestClient restClient;
  final ChatServer chat;
  final String classificationId;

  void _onAuthMessage(
    AuthMessage event,
    Emitter<AuthState> emit,
  ) {
    AuthStatus lastStatus = state.status; // save current status
    emit(state.copyWith(status: AuthStatus.loading));
    return emit(state.copyWith(status: lastStatus, message: event.message));
  }

  Future<void> _onAuthLoad(
    AuthLoad event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    Authenticate defaultAuthenticate =
        Authenticate(classificationId: classificationId);
    try {
      // check connection with default company
      Companies? companies = await restClient.getCompanies(limit: 1);
      defaultAuthenticate = Authenticate(
          company:
              companies.companies.isEmpty ? Company() : companies.companies[0],
          classificationId: classificationId);
      // get session data from last time
      Authenticate? localAuthenticate =
          await PersistFunctions.getAuthenticate();
      if (localAuthenticate != null &&
          localAuthenticate.apiKey != null &&
          localAuthenticate.company?.partyId != null) {
        // check if company still valid
        Companies? companies = await restClient.getCompanies(
            limit: 1, searchString: localAuthenticate.company!.partyId!);
        if (companies.companies.isEmpty) {
          return emit(state.copyWith(
              status: AuthStatus.unAuthenticated,
              authenticate: defaultAuthenticate));
        }
        // test apiKey and get Authenticate
        Authenticate authResult = await restClient.getAuthenticate(
            classificationId: classificationId);
        // Api key invalid or not present: UnAuthenticated
        if (authResult.apiKey == null) {
          return emit(state.copyWith(status: AuthStatus.unAuthenticated));
        }
        //Authenticated
        emit(state.copyWith(
            status: AuthStatus.authenticated, authenticate: authResult));
        await PersistFunctions.persistAuthenticate(state.authenticate!);
        chat.connect(
            state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
      } else {
        // UnAuthenticated
        emit(state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: defaultAuthenticate));
      }
    } on DioException catch (e) {
      await PersistFunctions.persistAuthenticate(defaultAuthenticate);
      emit(state.copyWith(
          status: AuthStatus.failure,
          authenticate: defaultAuthenticate,
          message: getDioError(e)));
    }
  }

  Future<void> _onAuthRegisterCompanyAndAdmin(
    AuthRegisterCompanyAndAdmin event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      Authenticate authenticate = await restClient.registerCompanyAdmin(
        emailAddress: event.user.email!,
        companyName: event.user.company!.name!,
        currencyId: event.currencyId,
        firstName: event.user.firstName!,
        lastName: event.user.lastName!,
        companyEmailAddress: event.user.email!,
        demoData: event.demoData,
        classificationId: classificationId,
        // when debug mode password is always qqqqqq9!
        newPassword: kReleaseMode ? null : 'qqqqqq9!',
      );
      emit(state.copyWith(
          status: AuthStatus.unAuthenticated,
          authenticate: authenticate,
          message: 'Register Company and Admin successful,'
              'you can now login with the password sent by email'));
      await PersistFunctions.persistAuthenticate(state.authenticate!);
    } on DioException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: getDioError(e)));
    }
  }

/*  Future<void> _onAuthRegisterUserEcommerce(
    AuthRegisterUserEcommerce event,
    Emitter<AuthState> emit,
  ) async {
    ApiResult<List<User>> apiResult = await restClient.registerUser(
        event.user.copyWith(userGroup: UserGroup.customer),
        state.authenticate!.company!.partyId!);
    emit(apiResult.when(
        success: (User data) {
          emit(state.copyWith(status: AuthStatus.registered));
          return state.copyWith(
              status: AuthStatus.unAuthenticated,
              message: '          Register successful,\n'
                  'you can now login with the password sent by email.',
              authenticate: state.authenticate!.copyWith(user: data[0]));
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: AuthStatus.failure, message: NetworkExceptions.getErrorMessage(error))));
    if (state.status == AuthStatus.registered) {
      await PersistFunctions.persistAuthenticate(state.authenticate!);
    }
  }
*/
  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      await restClient.logout();
      emit(state.copyWith(
          authenticate: state.authenticate!.copyWith(apiKey: null),
          status: AuthStatus.unAuthenticated,
          message: "Logged off"));
      PersistFunctions.persistAuthenticate(state.authenticate!);
    } on DioException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: getDioError(e)));
    }
  }

  Future<void> _onAuthLogin(
    AuthLogin event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      Authenticate authenticate = await restClient.login(
        username: event.username,
        password: event.password,
        classificationId: classificationId,
      );
      if (authenticate.apiKey != null) {
        if (authenticate.apiKey == 'passwordChange') {
          return emit(state.copyWith(
              status: AuthStatus.passwordChange,
              authenticate: authenticate,
              message: 'need to change password'));
        }
        emit(state.copyWith(
            status: AuthStatus.authenticated,
            authenticate: authenticate,
            message: 'You are logged in now...'));
        PersistFunctions.persistAuthenticate(state.authenticate!);
        chat.connect(
            state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
        var box = await Hive.openBox('growerp');
        box.put('apiKey', authenticate.apiKey);
      } else {
        emit(state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: authenticate,
            message: 'Login did not work...'));
      }
    } on DioException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: getDioError(e)));
    }
  }

  Future<void> _onAuthResetPassword(
    AuthResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.sendPassword));
      await restClient.resetPassword(username: event.username);
      emit(state.copyWith(
          status: AuthStatus.unAuthenticated,
          message: 'An email with password has been '
              'send to ${event.username}'));
    } on DioException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: getDioError(e)));
    }
  }

  Future<void> _onAuthChangePassword(
    AuthChangePassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      Authenticate result = await restClient.updatePassword(
          username: event.username,
          oldPassword: event.oldPassword,
          newPassword: event.newPassword);
      emit(state.copyWith(
          status: AuthStatus.authenticated,
          authenticate: result,
          message:
              'password successfully changed for user: ${event.username}'));
      PersistFunctions.persistAuthenticate(state.authenticate!);
      chat.connect(
          state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
    } on DioException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: getDioError(e)));
    }
  }
}
