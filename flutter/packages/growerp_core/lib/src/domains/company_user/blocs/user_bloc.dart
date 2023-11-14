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

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'user_event.dart';
part 'user_state.dart';

const _userLimit = 20;

mixin LeadBloc on Bloc<UserEvent, UserState> {}
mixin CustomerBloc on Bloc<UserEvent, UserState> {}
mixin EmployeeBloc on Bloc<UserEvent, UserState> {}
mixin SupplierBloc on Bloc<UserEvent, UserState> {}

EventTransformer<E> userDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class UserBloc extends Bloc<UserEvent, UserState>
    with LeadBloc, CustomerBloc, EmployeeBloc, SupplierBloc {
  UserBloc(this.restClient, this.role) : super(const UserState()) {
    on<UserFetch>(_onUserFetch,
        transformer: userDroppable(const Duration(milliseconds: 100)));
    on<UserUpdate>(_onUserUpdate);
    on<UserDelete>(_onUserDelete);
  }

  final RestClient restClient;
  final Role? role;
  int start = 0;

  Future<void> _onUserFetch(
    UserFetch event,
    Emitter<UserState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') {
      return;
    }
    if (state.status == UserStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.users.length;
    }
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: UserStatus.loading));

      Users compResult = await restClient.getUser(
          start: start,
          limit: event.limit,
          role: role,
          searchString: event.searchString);

      return emit(state.copyWith(
        status: UserStatus.success,
        users: start == 0
            ? compResult.users
            : (List.of(state.users)..addAll(compResult.users)),
        hasReachedMax: compResult.users.length < event.limit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: UserStatus.failure, users: [], message: getDioError(e)));
    }
  }

  Future<void> _onUserUpdate(
    UserUpdate event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(state.copyWith(status: UserStatus.loading));
      List<User> users = List.from(state.users);
      if (event.user.partyId != null) {
        User compResult = await restClient.updateUser(user: event.user);
        if (users.isNotEmpty) {
          int index = users
              .indexWhere((element) => element.partyId == event.user.partyId);
          users[index] = compResult;
        } else {
          users.add(compResult);
        }
        return emit(state.copyWith(
            searchString: '',
            status: UserStatus.success,
            users: users,
            message:
                'user ${compResult.firstName} ${compResult.lastName} updated...'));
      } else {
        // add
        User compResult = await restClient.createUser(user: event.user);
        users.insert(0, compResult);
        return emit(state.copyWith(
            searchString: '',
            status: UserStatus.success,
            users: users,
            message:
                'user ${compResult.firstName} ${compResult.lastName} added...'));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: UserStatus.failure, users: [], message: getDioError(e)));
    }
  }

  Future<void> _onUserDelete(
    UserDelete event,
    Emitter<UserState> emit,
  ) async {
    try {
      List<User> users = List.from(state.users);
      await restClient.deleteUser(
          partyId: event.user.partyId!, deleteCompanyToo: false);
      int index =
          users.indexWhere((element) => element.partyId == event.user.partyId);
      users.removeAt(index);
      return emit(state.copyWith(
          searchString: '',
          status: UserStatus.success,
          users: users,
          message: 'User ${event.user.firstName} is deleted now..'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: UserStatus.failure, users: [], message: getDioError(e)));
    }
  }
}
