import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:models/models.dart';

class CrmBloc extends Bloc<CrmEvent, CrmState> {
  final repos;
  CrmBloc(this.repos)
      : assert(repos != null),
        super(CrmInitial());
  List<User> crmUsers = [];

  @override
  Stream<CrmState> mapEventToState(
    CrmEvent event,
  ) async* {
    if (event is LoadCrm) {
      yield CrmLoading('updating');
      dynamic result = await repos.getUser(userGroupId: 'GROWERP_M_CUSTOMER');
      if (result is List<User>) {
        crmUsers = result;
        yield CrmLoaded(result);
      } else {
        yield CrmProblem(result);
      }
    } else if (event is UpdateCrmUser) {
      yield CrmLoading(
          (event.crmUser?.partyId == null ? "Adding " : "Updating") +
              " user ${event.crmUser}");
      dynamic result = await repos.updateUser(event.crmUser);
      if (result is User) {
        if (event.crmUser.partyId == null)
          crmUsers.add(result);
        else {
          // update
          int index =
              crmUsers.indexWhere((user) => user.partyId == result.partyId);
          crmUsers.replaceRange(index, index + 1, [result]);
        }
        yield CrmLoaded(crmUsers,
            'User ' + (event.crmUser?.partyId == null ? 'Added' : 'Updated'));
      } else {
        yield CrmProblem(result);
      }
    } else if (event is DeleteCrmUser) {
      yield CrmLoading("Deleting user ${event.crmUser}");
      dynamic result = await repos.deleteUser(event.crmUser.partyId);
      if (result == event.crmUser.partyId) {
        int index = crmUsers.indexWhere((user) => user.partyId == result);
        crmUsers.removeAt(index);
        yield CrmLoaded(crmUsers, 'User ${event.crmUser} deleted');
      } else {
        yield CrmProblem(result);
      }
    }
  }
}
//##################### events #########################

abstract class CrmEvent extends Equatable {
  const CrmEvent();

  @override
  List<Object> get props => [];
}

class LoadCrm extends CrmEvent {
  final String companyPartyId;
  LoadCrm([this.companyPartyId]);
  @override
  String toString() => 'LoadCrm using company: $companyPartyId';
}

class UpdateCrmUser extends CrmEvent {
  final User crmUser;
  UpdateCrmUser(this.crmUser);
  @override
  String toString() => 'Create/Update CrmUser { $crmUser }';
}

class DeleteCrmUser extends CrmEvent {
  final User crmUser;
  DeleteCrmUser(this.crmUser);
  @override
  String toString() => 'Delete CrmUser { $crmUser }';
}

//##################### state ##########################
abstract class CrmState extends Equatable {
  const CrmState();
  @override
  List<Object> get props => [];
}

class CrmInitial extends CrmState {}

class CrmLoading extends CrmState {
  final String message;
  CrmLoading(this.message);
  @override
  String toString() => 'CrmLoading: { $message }';
}

class CrmProblem extends CrmState {
  final String errorMessage;
  CrmProblem(this.errorMessage);
  @override
  String toString() => 'CrmProblem { $errorMessage }';
}

class CrmLoaded extends CrmState {
  final List<User> crmUsers;
  final String message;
  CrmLoaded(this.crmUsers, [this.message]);
  @override
  String toString() => 'CrmLoaded { crmUsers#: ${crmUsers?.length} }';
}
