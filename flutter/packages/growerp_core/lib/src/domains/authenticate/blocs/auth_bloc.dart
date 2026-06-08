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
import 'dart:ui' show Locale;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:credit_card_type_detector/credit_card_type_detector.dart';

import '../../../services/ws_client.dart';
import '../../../services/build_dio_client.dart';
import '../../../services/get_dio_error.dart';
import '../../../services/startup_credentials.dart';
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
  AuthBloc(
    this.chat,
    this.notification,
    this.restClient,
    this.classificationId,
    this.company,
  ) : super(const AuthState()) {
    on<AuthUpdateLocal>(_onAuthUpdateLocal);
    on<AuthLoad>(_onAuthLoad);
    on<AuthRegister>(
      _onAuthRegister,
      transformer: authDroppable(const Duration(milliseconds: 100)),
    );
    on<AuthLoggedOut>(
      _onAuthLoggedOut,
      transformer: authDroppable(const Duration(milliseconds: 100)),
    );
    on<AuthLogin>(
      _onAuthLogin,
      transformer: authDroppable(const Duration(milliseconds: 100)),
    );
    on<AuthResetPassword>(_onAuthResetPassword);
    on<AuthChangePassword>(_onAuthChangePassword);
  }

  final RestClient restClient;
  final WsClient chat;
  final WsClient notification;
  final String classificationId;
  final Company? company;

  void _onAuthUpdateLocal(AuthUpdateLocal event, Emitter<AuthState> emit) {
    emit(state.copyWith(authenticate: event.authenticate));
  }

  Future<void> _onAuthLoad(AuthLoad event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    Authenticate defaultAuthenticate = Authenticate(
      classificationId: classificationId,
    );
    // get session data from last time
    Authenticate? localAuthenticate = await PersistFunctions.getAuthenticate();
    if (localAuthenticate != null) {
      defaultAuthenticate = localAuthenticate;
    }

    try {
      // load currencies from backend
      await loadCurrencies(restClient);
      // check connection with default company
      Companies? companies = await restClient.getCompanies(
        searchString: defaultAuthenticate.company?.partyId ?? company?.partyId,
        limit: 1,
      );
      defaultAuthenticate = defaultAuthenticate.copyWith(
        company: companies.companies.isEmpty
            ? Company()
            : companies.companies[0],
      );

      if (localAuthenticate != null && localAuthenticate.apiKey != null) {
        // check if company still valid; skip if no company (support users) or DefaultSettings
        if (localAuthenticate.company?.partyId != null &&
            localAuthenticate.company!.partyId != 'DefaultSettings') {
          Companies? companies = await restClient.getCompanies(
            limit: 1,
            searchString: localAuthenticate.company!.partyId!,
          );
          if (companies.companies.isEmpty) {
            return emit(
              state.copyWith(
                status: AuthStatus.unAuthenticated,
                authenticate: defaultAuthenticate,
              ),
            );
          }
        }
        // test apiKey and get Authenticate
        Authenticate authResult = await restClient.getAuthenticate(
          classificationId: classificationId,
        );
        // Api key invalid or not present: UnAuthenticated
        if (authResult.apiKey == null) {
          if (_applyStartupCredentials(defaultAuthenticate, emit)) return;
          return emit(
            state.copyWith(
              status: AuthStatus.unAuthenticated,
              authenticate: defaultAuthenticate,
            ),
          );
        }
        // Authenticated
        await PersistFunctions.persistAuthenticate(authResult);
        // chat
        await chat.connect(authResult.apiKey!, authResult.user!.userId!);
        // notification
        await notification.connect(
          authResult.apiKey!,
          authResult.user!.userId!,
        );
        return emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            authenticate: authResult,
          ),
        );
      } else {
        // UnAuthenticated — honor web startup-page credentials if present
        if (_applyStartupCredentials(defaultAuthenticate, emit)) return;
        return emit(
          state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: defaultAuthenticate,
          ),
        );
      }
    } on DioException catch (e) {
      // if connection error, don't wipe session
      if (e.type != DioExceptionType.connectionError &&
          e.type != DioExceptionType.connectionTimeout &&
          e.type != DioExceptionType.sendTimeout &&
          e.type != DioExceptionType.receiveTimeout) {
        await PersistFunctions.persistAuthenticate(defaultAuthenticate);
      }
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          authenticate: state.authenticate ?? defaultAuthenticate,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Applies credentials handed off by the web startup page (see
  /// admin/web/index.html) to an otherwise unauthenticated result. When the
  /// email exists it logs in automatically; otherwise it emits an
  /// unauthenticated state flagged for registration (the landing auto-opens the
  /// prefilled register dialog). Returns true when credentials were consumed so
  /// the caller skips its own unauthenticated emit. Always false on non-web.
  bool _applyStartupCredentials(Authenticate auth, Emitter<AuthState> emit) {
    final creds = getStartupCredentials();
    if (creds == null) return false;
    final authWithEmail = auth.copyWith(
      user: (auth.user ?? User()).copyWith(loginName: creds.email),
    );
    if (creds.isRegister) {
      if (creds.firstName != null && creds.lastName != null) {
        // The HTML register dialog collected name + email → register directly
        // (new company + admin), matching RegisterUserDialog(admin: true).
        emit(
          state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: authWithEmail,
          ),
        );
        add(
          AuthRegister(
            User(
              company: company,
              firstName: creds.firstName,
              lastName: creds.lastName,
              email: creds.email,
              userGroup: UserGroup.admin,
            ),
            newPassword: creds.password,
          ),
        );
      } else {
        // Fallback (only email known) → open the prefilled register dialog.
        emit(
          state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: authWithEmail,
            pendingRegistrationEmail: creds.email,
            pendingRegistrationPassword: creds.password,
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.unAuthenticated,
          authenticate: authWithEmail,
        ),
      );
      add(AuthLogin(creds.email, creds.password ?? ''));
    }
    return true;
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
        userGroup: event.user.userGroup!,
        // Caller-chosen password (e.g. from the web startup page) wins;
        // otherwise debug builds default to qqqqqq9!, release emails a temp one.
        newPassword: event.newPassword ?? (kReleaseMode ? null : 'qqqqqq9!'),
        timeZoneOffset: DateTime.now().timeZoneOffset.toString(),
        locale: (event.locale ?? PlatformDispatcher.instance.locale)
            .toLanguageTag(),
      );
      await PersistFunctions.persistAuthenticate(result);
      emit(
        state.copyWith(
          status: AuthStatus.unAuthenticated,
          authenticate: result,
          message:
              'Registration successful.\n'
              'You can now login with the password sent by email',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          authenticate: Authenticate(classificationId: classificationId),
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onAuthLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      await restClient.logout();
      await clearRestCache();
      notification.close();
      chat.close();
      emit(
        state.copyWith(
          status: AuthStatus.unAuthenticated,
          message: "Logged off",
        ),
      );
      PersistFunctions.persistAuthenticate(
        state.authenticate!.copyWith(apiKey: null),
      );
      PersistFunctions.persistKeyValue('apiKey', '');
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    try {
      String? creditCardType;
      if (event.creditCardNumber != null) {
        var cardType = detectCCType(event.creditCardNumber!);
        if (cardType.isNotEmpty) {
          var cardType1 = cardType[0].prettyType;
          creditCardType = cardType1.toString().split('.').last.toString();
        }
      }

      emit(state.copyWith(status: AuthStatus.loading));
      PersistFunctions.removeAuthenticate();

      // Use extended timeout for demo data creation as it involves heavy database operations
      final clientToUse = event.demoData == true
          ? RestClient(
              await buildDioClient(timeout: const Duration(seconds: 900)),
            ) // 15 minutes for demo data
          : restClient;

      Authenticate authenticate = await clientToUse.login(
        username: event.username,
        password: event.password,
        companyName: event.companyName,
        currencyId: event.currency?.currencyId,
        demoData: event.demoData,
        creditCardNumber: event.creditCardNumber,
        creditCardType: creditCardType,
        nameOnCard: event.nameOnCard,
        expireMonth: event.expireMonth,
        expireYear: event.expireYear,
        cVC: event.cVC,
        plan: event.plan,
        classificationId: classificationId,
        timeZoneOffset: DateTime.now().timeZoneOffset.toString(),
        testDaysOffset: event.testDaysOffset,
      );

      if (authenticate.loginStatus == null ||
          ![
            'setupRequired', // Admin needs to provide company info
            'subscriptionExpired', // Subscription expired, payment required
            'registered', // User registered for existing company
            'passwordChange', // Password reset required
          ].contains(authenticate.loginStatus)) {
        
        if (authenticate.user?.userId != null) {
          await chat.connect(
            authenticate.apiKey!,
            authenticate.user!.userId!,
          );
          await notification.connect(
            authenticate.apiKey!,
            authenticate.user!.userId!,
          );
        }

        // no special status so save and authenticated
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            authenticate: authenticate,
            // No message here - dialogs handle their own messages
          ),
        );
        PersistFunctions.persistAuthenticate(state.authenticate!);

        PersistFunctions.persistKeyValue('apiKey', authenticate.apiKey ?? '');
        PersistFunctions.persistKeyValue(
          'moquiSessionToken',
          authenticate.moquiSessionToken ?? '',
        );
      } else {
        // login in process
        emit(
          state.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: authenticate,
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onAuthResetPassword(
    AuthResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.sendPassword));
      await restClient.resetPassword(username: event.username);
      emit(
        state.copyWith(
          status: AuthStatus.unAuthenticated,
          message:
              'An email with password has been '
              'send to ${event.username}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: await getDioError(e),
        ),
      );
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
        classificationId: classificationId,
      );
      if (state.authenticate!.user!.userId != null) {
        await chat.connect(
          state.authenticate!.apiKey!,
          state.authenticate!.user!.userId!,
        );
        await notification.connect(
          state.authenticate!.apiKey!,
          state.authenticate!.user!.userId!,
        );
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          authenticate: result,
          message: 'passwordChangeSuccess:${event.username}',
        ),
      );
      PersistFunctions.persistKeyValue('apiKey', result.apiKey ?? '');
      PersistFunctions.persistAuthenticate(
        state.authenticate!.copyWith(apiKey: result.apiKey),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
