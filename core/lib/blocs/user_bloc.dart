import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:models/models.dart';
import 'package:rxdart/rxdart.dart';

const pageLength = 20;

class CustomerBloc extends UserBloc {
  CustomerBloc(repos) : super(repos, "GROWERP_M_CUSTOMER");
}

class EmployeeBloc extends UserBloc {
  EmployeeBloc(repos) : super(repos, "GROWERP_M_EMPLOYEE");
}

class AdminBloc extends UserBloc {
  AdminBloc(repos) : super(repos, "GROWERP_M_ADMIN");
}

class LeadBloc extends UserBloc {
  LeadBloc(repos) : super(repos, "GROWERP_M_LEAD");
}

class SupplierBloc extends UserBloc {
  SupplierBloc(repos) : super(repos, "GROWERP_M_SUPPLIER");
}

class UserBloc extends Bloc<UserEvent, UserState> {
  final repos;
  final String userGroupId;
  UserBloc(this.repos, [this.userGroupId])
      : assert(repos != null, userGroupId != null),
        super(UserInitial());
  List<User> users;
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
      if (currentState is UserInitial) {
        dynamic result = await repos.getUser(
            userGroupId: userGroupId, start: 0, limit: event.limit);
        if (result is List<User>) {
          yield UserFetchSuccess(
              users: result,
              hasReachedMax: result.length < event.limit ? true : false);
        } else
          yield UserProblem(result);
        return;
      }
      if (currentState is UserFetchSuccess) {
        //no UserLoading here, will use copyWith..
        dynamic result = await repos.getUser(
            userGroupId: userGroupId,
            start: currentState.users.length,
            limit: event.limit);
        if (result is List<User>) {
          if (result.length < event.limit)
            yield UserFetchSuccess(
                users: currentState.users + result, hasReachedMax: true);
          else
            yield UserFetchSuccess(
                users: currentState.users + result, hasReachedMax: false);
        } else {
          yield UserProblem(result);
        }
      }
    } else if (event is UpdateUser) {
      yield UserLoading((event.user?.partyId == null ? "Adding " : "Updating") +
          " user ${event.user}");
      dynamic result = await repos.updateUser(event.user);
      if (currentState is UserFetchSuccess) {
        if (result is User) {
          if (event.user?.partyId == null) {
            yield UserFetchSuccess(
                users: currentState.users + [result],
                hasReachedMax: currentState.hasReachedMax);
          } else {
            yield UserFetchSuccess(
                users: currentState.users,
                hasReachedMax: currentState.hasReachedMax);
          }
        } else {
          yield UserProblem(result);
        }
      }
    } else if (event is DeleteUser) {
      yield UserLoading("Deleting user ${event.user}");
      dynamic result = await repos.deleteUser(event.user.partyId);
      if (currentState is UserFetchSuccess) {
        if (result == event.user.partyId) {
          int index =
              currentState.users.indexWhere((user) => user.partyId == result);
          currentState.users.removeAt(index);
          yield UserFetchSuccess(
              users: currentState.users,
              hasReachedMax: currentState.hasReachedMax);
        } else {
          yield UserProblem(result);
        }
      }
    }
  }
}

bool _hasReachedMax(UserState state) =>
    state is UserFetchSuccess && state.hasReachedMax;
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
  final String userGroupId;
  final int limit;
  FetchUser({this.userGroupId, this.limit});
  @override
  String toString() => 'FetchUser using userGroup: $userGroupId '
      'limit: $limit';
}

class UpdateUser extends UserEvent {
  final User user;
  final String imagePath;
  UpdateUser(this.user, this.imagePath);
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

class UserFetchSuccess extends UserState {
  final List<User> users;
  final bool hasReachedMax;

  UserFetchSuccess({this.users, this.hasReachedMax});

  UserFetchSuccess copyWith({List<User> users, bool hasReachedMax}) {
    return UserFetchSuccess(
      users: users ?? this.users,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [users, hasReachedMax];

  @override
  String toString() =>
      'UserFetchSuccess { length: ${users.length}, usersMax: $hasReachedMax }';
}
