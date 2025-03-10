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
import 'package:stream_transform/stream_transform.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../services/ws_client.dart';
import '../../common/functions/functions.dart';

part 'auth_event.dart';
part 'auth_state.dart';

EventTransformer<E> authDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Authbloc controls the connection to the backend
///
/// It contains company and user information and signals connection errrors,
/// keeps the token and apiKey in the [Authenticate] class.
///
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.chat, this.notification, this.restClient, this.classificationId,
      this.company)
      : super(const AuthState()) {
//    on<AuthUpdateLocal>(_onAuthUpdateLocal);
    on<AuthLoad>(_onAuthLoad);
    on<AuthRegister>(_onAuthRegister,
        transformer: authDroppable(const Duration(milliseconds: 100)));
    on<AuthLoggedOut>(_onAuthLoggedOut,
        transformer: authDroppable(const Duration(milliseconds: 100)));
    on<AuthLogin>(_onAuthLogin,
        transformer: authDroppable(const Duration(milliseconds: 100)));
    on<AuthResetPassword>(_onAuthResetPassword);
    on<AuthChangePassword>(_onAuthChangePassword);
  }

  final RestClient restClient;
  final WsClient chat;
  final WsClient notification;
  final String classificationId;
  final Company? company;

  Future<void> _onAuthLoad(
    AuthLoad event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    Authenticate defaultAuthenticate =
        Authenticate(classificationId: classificationId);
    try {
      // check connection with default company
      Companies? companies = await restClient.getCompanies(
          searchString: company?.partyId, limit: 1);
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
        // check if company still valid, not for user support
        if (localAuthenticate.company!.partyId != 'DefaultSettings') {
          Companies? companies = await restClient.getCompanies(
              limit: 1, searchString: localAuthenticate.company!.partyId!);
          if (companies.companies.isEmpty) {
            return emit(state.copyWith(
                status: AuthStatus.unAuthenticated,
                authenticate: defaultAuthenticate));
          }
        }
        // test apiKey and get Authenticate
        Authenticate authResult = await restClient.getAuthenticate(
            classificationId: classificationId);
        // Api key invalid or not present: UnAuthenticated
        if (authResult.apiKey == null) {
          return emit(state.copyWith(status: AuthStatus.unAuthenticated));
        }
        // Authenticated
        await PersistFunctions.persistAuthenticate(authResult);
        // chat
        chat.connect(authResult.apiKey!, authResult.user!.userId!);
        // notification
        notification.connect(authResult.apiKey!, authResult.user!.userId!);
        return emit(state.copyWith(
            status: AuthStatus.authenticated, authenticate: authResult));
      } else {
        // UnAuthenticated
        return emit(state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: defaultAuthenticate));
      }
    } on DioException catch (e) {
      var box = await Hive.openBox('growerp');
      await box.clear();
      await PersistFunctions.persistAuthenticate(defaultAuthenticate);
      emit(state.copyWith(
          status: AuthStatus.failure,
          authenticate: defaultAuthenticate,
          message: await getDioError(e)));
    }
  }

  Future<void> _onAuthRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      final result = await restClient.register(
        classificationId: classificationId,
        email: event.user.email!,
        companyPartyId: event.user.company?.partyId,
        firstName: event.user.firstName!,
        lastName: event.user.lastName!,
        // when debug mode password is always qqqqqq9!
        newPassword: kReleaseMode ? null : 'qqqqqq9!',
      );
      await PersistFunctions.persistAuthenticate(result);
      emit(state.copyWith(
          status: AuthStatus.unAuthenticated,
          authenticate: result,
          message: 'Registration successful.\n'
              'You can now login with the password sent by email'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: AuthStatus.failure,
          authenticate: Authenticate(classificationId: classificationId),
          message: await getDioError(e)));
    }
  }

  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      await restClient.logout();
      notification.close();
      chat.close();
      emit(state.copyWith(
          authenticate: state.authenticate!.copyWith(apiKey: null),
          status: AuthStatus.unAuthenticated,
          message: "Logged off"));
      PersistFunctions.persistAuthenticate(state.authenticate!);
    } on DioException catch (e) {
      emit(state.copyWith(
          status: AuthStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onAuthLogin(
    AuthLogin event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      PersistFunctions.removeAuthenticate();
      Authenticate authenticate = await restClient.login(
        username: event.username,
        password: event.password,
        extraInfo: event.extraInfo,
        companyName: event.companyName,
        currencyId: event.currency?.currencyId,
        demoData: event.demoData,
        classificationId: classificationId,
      );
      if (authenticate.apiKey != null &&
          !['moreInfo', 'passwordChange'].contains(authenticate.apiKey)) {
        // apiKey found so save and authenticated
        emit(state.copyWith(
            status: AuthStatus.authenticated,
            authenticate: authenticate,
            message: 'You are logged in now...'));
        PersistFunctions.persistAuthenticate(state.authenticate!);
        if (state.authenticate!.user!.userId != null) {
          chat.connect(
              state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
          notification.connect(
              state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
        }

        var box = await Hive.openBox('growerp');
        box.put('apiKey', authenticate.apiKey);
      } else {
        // either login in process or failed....
        emit(state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: authenticate,
            message:
                ['moreInfo', 'passwordChange'].contains(authenticate.apiKey)
                    ? null
                    : 'Login did not work...'));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: AuthStatus.failure, message: await getDioError(e)));
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
      emit(state.copyWith(
          status: AuthStatus.failure, message: await getDioError(e)));
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
          newPassword: event.newPassword,
          classificationId: classificationId);
      if (state.authenticate!.user!.userId != null) {
        chat.connect(
            state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
        notification.connect(
            state.authenticate!.apiKey!, state.authenticate!.user!.userId!);
      }

      emit(state.copyWith(
          status: AuthStatus.authenticated,
          authenticate: result,
          message:
              'password successfully changed for user: ${event.username}'));
      var box = await Hive.openBox('growerp');
      box.put('apiKey', result.apiKey);
      PersistFunctions.persistAuthenticate(
          state.authenticate!.copyWith(apiKey: result.apiKey));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: AuthStatus.failure, message: await getDioError(e)));
    }
  }
}
