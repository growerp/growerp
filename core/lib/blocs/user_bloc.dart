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
  final String userGroupId;
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
    final currentState = state;
    if (event is FetchUser && !_hasReachedMax(currentState)) {
      print("====curstate: $currentState event limit: ${event.limit}");
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
      }
      if (currentState is UserSuccess) {
        dynamic result = await repos.getUser(
            userGroupId: userGroupId,
            start: currentState.users.length,
            limit: event.limit);
        if (result is List<User>) {
          if (result.length < event.limit)
            yield currentState.copyWith(
                users: currentState.users + result, hasReachedMax: true);
          else
            yield currentState.copyWith(
                users: currentState.users + result, hasReachedMax: false);
        } else {
          yield UserProblem(result);
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
            int index = currentState.users
                .indexWhere((p) => p.partyId == result.partyId);
            print("userbloc userupdate before: ${currentState.users[index]}");
            currentState.users.replaceRange(index, index + 1, [result]);
            print("userbloc userupdate after: ${currentState.users[index]}");
          }
          yield UserSuccess(
                  users: currentState.users,
                  hasReachedMax: currentState.hasReachedMax)
              .copyWith(message: 'User ' + (adding ? 'added' : 'updated'));
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
              currentState.users.indexWhere((user) => user.partyId == result);
          currentState.users.removeAt(index);
          yield UserSuccess(
                  users: currentState.users,
                  hasReachedMax: currentState.hasReachedMax)
              .copyWith(message: 'User $name deleted');
        } else {
          yield UserProblem(result);
        }
      }
    }
  }
}

bool _hasReachedMax(UserState state) =>
    state is UserSuccess && state.hasReachedMax;
//##################### events #########################

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object> get props => [];
}

class LoadUser extends UserEvent {
  final String userGroupId;
  LoadUser([this.userGroupId]);
  @override
  String toString() => 'LoadUser using groupId: $userGroupId';
}

class FetchUser extends UserEvent {
  final int limit;
  FetchUser({this.limit});
  @override
  String toString() => 'FetchUser with limit $limit';
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
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {
  final String message;
  UserLoading([this.message]);
  @override
  String toString() => 'UserLoading: { $message }';
}

class UserProblem extends UserState {
  final String errorMessage;
  UserProblem(this.errorMessage);
  @override
  String toString() => 'UserProblem { $errorMessage }';
}

class UserLoaded extends UserState {
  final User user;
  final String message;

  UserLoaded(this.user, [this.message]);

  String toString() => 'UserLoaded { $User }';
}

class UserSuccess extends UserState {
  final List<User> users;
  final message;
  final bool hasReachedMax;

  const UserSuccess({this.users, this.message, this.hasReachedMax});

  UserSuccess copyWith({List<User> users, String message, bool hasReachedMax}) {
    return UserSuccess(
      users: users ?? this.users,
      message: message ?? this.message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [users, hasReachedMax];

  @override
  String toString() =>
      'UserSuccess { length: ${users.length}, usersMax: $hasReachedMax }';
}
