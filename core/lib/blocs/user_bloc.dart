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
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:models/@models.dart';
import 'package:rxdart/rxdart.dart';

const pageLength = 20;

mixin LeadBloc on Bloc<UserEvent, UserState> {}
mixin CustomerBloc on Bloc<UserEvent, UserState> {}
mixin EmployeeBloc on Bloc<UserEvent, UserState> {}
mixin AdminBloc on Bloc<UserEvent, UserState> {}
mixin SupplierBloc on Bloc<UserEvent, UserState> {}

class UserBloc extends Bloc<UserEvent, UserState>
    with LeadBloc, CustomerBloc, EmployeeBloc, AdminBloc, SupplierBloc {
  final repos;
  final String? userGroupId;
  UserBloc(this.repos, [this.userGroupId])
      : assert(repos != null, userGroupId != null),
        super(UserInitial());

  @override
  Stream<Transition<UserEvent, UserState>> transformEvents(
    Stream<UserEvent> events,
    TransitionFunction<UserEvent, UserState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    final UserState currentState = state;
    if (event is FetchUser) {
      if (currentState is UserInitial) {
        dynamic result = await repos.getUser(
            userGroupId: userGroupId, start: 0, limit: event.limit);
        if (result is List<User>) {
          yield UserSuccess(
              users: result,
              hasReachedMax: result.length < event.limit ? true : false);
        } else
          yield UserProblem(result);
        return;
      } else if (currentState is UserSuccess) {
        if (event.searchString != null && currentState.searchString == null ||
            (currentState.searchString != null &&
                event.searchString != currentState.searchString)) {
          yield UserLoading("Searching for ${event.searchString}");
          dynamic result = await repos.getUser(
              userGroupId: userGroupId,
              start: 0,
              limit: event.limit,
              search: event.searchString);
          if (result is List<User>) {
            yield currentState.copyWith(
                message: "result for search ${event.searchString}",
                users: currentState.users! + result,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield currentState.copyWith(message: result, error: true);
          return;
        } else if (!_hasReachedMax(currentState)) {
          dynamic result = await repos.getUser(
              start: currentState.users!.length,
              limit: event.limit,
              search: event.searchString,
              userGroupId: userGroupId);
          if (result is List<User>) {
            yield currentState.copyWith(
                users: currentState.users! + result,
                searchString: event.searchString,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield currentState.copyWith(message: result, error: true);
        }
      }
    } else if (event is UpdateUser) {
      bool adding = event.user.partyId == null;
      yield UserLoading((adding ? "Adding " : "Updating") +
          " user ${event.user.firstName} ${event.user.lastName}");
      dynamic result = await repos.updateUser(event.user);
      if (currentState is UserSuccess) {
        if (result is User) {
          if (adding) {
            currentState.users?.add(result);
          } else {
            int index = currentState.users!
                .indexWhere((p) => p.partyId == result.partyId);
            print("userbloc userupdate before: ${currentState.users![index]}");
            currentState.users!.replaceRange(index, index + 1, [result]);
            print("userbloc userupdate after: ${currentState.users![index]}");
          }
          yield currentState.copyWith(
              message: 'User ' + (adding ? 'added' : 'updated'));
        } else {
          yield UserProblem(result);
        }
      }
    } else if (event is DeleteUser) {
      if (currentState is UserSuccess) {
        String name = '${event.user.firstName} ${event.user.lastName}';
        yield UserLoading("Deleting user $name");
        dynamic result = await repos.deleteUser(event.user.partyId);
        if (result == event.user.partyId) {
          int index =
              currentState.users!.indexWhere((user) => user.partyId == result);
          currentState.users!.removeAt(index);
          yield currentState.copyWith(message: 'User $name deleted');
        } else {
          yield currentState.copyWith(message: result, error: true);
        }
      }
    }
  }
}

bool _hasReachedMax(UserState state) =>
    state is UserSuccess && state.hasReachedMax!;
//##################### events #########################

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object> get props => [];
}

class LoadUser extends UserEvent {
  final String? userGroupId;
  LoadUser([this.userGroupId]);
  @override
  String toString() => 'LoadUser using groupId: $userGroupId';
}

class FetchUser extends UserEvent {
  final int limit;
  final String? searchString;
  FetchUser({this.limit = 20, this.searchString});
  @override
  String toString() => 'FetchUser with limit $limit search: $searchString';
}

class UpdateUser extends UserEvent {
  final User user;
  UpdateUser(this.user);
  @override
  String toString() => 'Create/Update User { $user }';
}

class DeleteUser extends UserEvent {
  final User user;
  DeleteUser(this.user);
  @override
  String toString() => 'Delete User { $user }';
}

//##################### state ##########################
abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {
  final String? message;
  UserLoading([this.message]);
  @override
  String toString() => 'UserLoading: { $message }';
}

class UserProblem extends UserState {
  final String? errorMessage;
  UserProblem(this.errorMessage);
  @override
  String toString() => 'UserProblem { $errorMessage }';
}

class UserLoaded extends UserState {
  final User user;
  final String? message;

  UserLoaded(this.user, [this.message]);

  String toString() => 'UserLoaded { $User }';
}

class UserSuccess extends UserState {
  final List<User>? users;
  final String? message;
  final bool error;
  final bool? hasReachedMax;
  final String? searchString;

  const UserSuccess(
      {this.users,
      this.message,
      this.error = false,
      this.hasReachedMax,
      this.searchString});

  UserSuccess copyWith(
      {List<User>? users,
      String? message,
      bool error = false,
      bool? hasReachedMax,
      String? searchString}) {
    return UserSuccess(
        users: users ?? this.users,
        message: message,
        error: error,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        searchString: searchString ?? this.searchString);
  }

  @override
  List<Object?> get props => [users, hasReachedMax];

  @override
  String toString() => 'UserSuccess { length: ${users!.length}, '
      'hasReachedMax: $hasReachedMax message $message error: $error}';
}
