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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:equatable/equatable.dart';

import '../../api_repository.dart';

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
  UserBloc(this.repos, this.role) : super(const UserState()) {
    on<UserFetch>(_onUserFetch,
        transformer: userDroppable(const Duration(milliseconds: 100)));
    on<UserUpdate>(_onUserUpdate);
    on<UserDelete>(_onUserDelete);
  }

  final CompanyUserAPIRepository repos;
  final Role? role;

  Future<void> _onUserFetch(
    UserFetch event,
    Emitter<UserState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    try {
      // start from record zero for initial and refresh
      if (state.status == UserStatus.initial || event.refresh) {
        emit(state.copyWith(status: UserStatus.loading));
        ApiResult<List<User>> compResult = await repos.getUser(
            start: 0,
            limit: _userLimit,
            role: role,
            searchString: event.searchString);
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: UserStatus.success,
                  users: data,
                  hasReachedMax: data.length < _userLimit ? true : false,
                  searchString: '',
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: UserStatus.failure,
                message: NetworkExceptions.getErrorMessage(error))));
      }
      // get first search page also for changed search
      if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
          (state.searchString.isNotEmpty &&
              event.searchString != state.searchString)) {
        emit(state.copyWith(status: UserStatus.loading));
        ApiResult<List<User>> compResult = await repos.getUser(
            start: 0,
            limit: _userLimit,
            role: role,
            searchString: event.searchString);
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: UserStatus.success,
                  users: data,
                  hasReachedMax: data.length < _userLimit ? true : false,
                  searchString: event.searchString,
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: UserStatus.failure,
                message: NetworkExceptions.getErrorMessage(error))));
        // get next page also for search
      }
      emit(state.copyWith(status: UserStatus.loading));
      ApiResult<List<User>> compResult = await repos.getUser(
          start: state.users.length,
          limit: _userLimit,
          role: role,
          searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: UserStatus.success,
                users: List.of(state.users)..addAll(data),
                hasReachedMax: data.length < _userLimit ? true : false,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: UserStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } catch (error) {
      emit(state.copyWith(
          status: UserStatus.failure, message: error.toString()));
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
        ApiResult<User> compResult = await repos.updateUser(event.user);
        return emit(compResult.when(
            success: (data) {
              if (users.isNotEmpty) {
                int index = users.indexWhere(
                    (element) => element.partyId == event.user.partyId);
                users[index] = data;
              } else {
                users.add(data);
              }
              return state.copyWith(
                  searchString: '',
                  status: UserStatus.success,
                  users: users,
                  message:
                      'user ${data.firstName} ${data.lastName} updated...');
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: UserStatus.failure,
                message: NetworkExceptions.getErrorMessage(error))));
      } else {
        // add
        ApiResult<User> compResult = await repos.createUser(event.user);
        return emit(compResult.when(
            success: (data) {
              users.insert(0, data);
              return state.copyWith(
                  searchString: '',
                  status: UserStatus.success,
                  users: users,
                  message: 'user ${data.firstName} ${data.lastName} added...');
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: UserStatus.failure,
                message: NetworkExceptions.getErrorMessage(error))));
      }
    } catch (error) {
      emit(state.copyWith(
          status: UserStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onUserDelete(
    UserDelete event,
    Emitter<UserState> emit,
  ) async {
    try {
      List<User> users = List.from(state.users);
      ApiResult<User> compResult =
          await repos.deleteUser(event.user.partyId!, false);
      return emit(compResult.when(
          success: (data) {
            int index = users
                .indexWhere((element) => element.partyId == event.user.partyId);
            users.removeAt(index);
            return state.copyWith(
                searchString: '',
                status: UserStatus.success,
                users: users,
                message: 'User ${event.user.firstName} is deleted now..');
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: UserStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } catch (error) {
      emit(state.copyWith(
          status: UserStatus.failure, message: error.toString()));
    }
  }
}
