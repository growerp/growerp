import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:models/models.dart';

class CrmBloc extends Bloc<CrmEvent, CrmState> {
  final repos;
  Crm crm = Crm(leads: [], customers: [], opportunities: []);
  CrmBloc(this.repos)
      : assert(repos != null),
        super(CrmInitial());

  @override
  Stream<CrmState> mapEventToState(
    CrmEvent event,
  ) async* {
    if (event is LoadCrm) {
      yield CrmLoading('initial load CRM');
      dynamic result = await repos.getCrm();
      if (result is Crm) {
        crm = result;
        yield CrmLoaded(result);
      } else {
        yield CrmProblem(result);
      }
    } else if (event is UpdateCrmUser) {
      List crmUsers = crm.leads;
      if (event.crmUser.userGroupId == "GROWERP_M_CUSTOMER")
        crmUsers = crm.customers;
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
        yield CrmLoaded(crm,
            'User ' + (event.crmUser?.partyId == null ? 'Added' : 'Updated'));
      } else {
        yield CrmProblem(result);
      }
    } else if (event is DeleteCrmUser) {
      List crmUsers = crm.leads;
      if (event.crmUser.userGroupId == "GROWERP_M_CUSTOMER")
        crmUsers = crm.customers;
      yield CrmLoading("Deleting user ${event.crmUser}");
      dynamic result = await repos.deleteUser(event.crmUser.partyId);
      if (result == event.crmUser.partyId) {
        int index = crmUsers.indexWhere((user) => user.partyId == result);
        crmUsers.removeAt(index);
        yield CrmLoaded(crm, 'User ${event.crmUser} deleted');
      } else {
        yield CrmProblem(result);
      }
    } else if (event is UpdateOpportunity) {
      yield CrmLoading(
          (event.opportunity?.opportunityId == null ? "Adding " : "Updating") +
              " opportunity: ${event.opportunity}");
      dynamic result = await repos.updateOpportunity(event.opportunity);
      if (result is Opportunity) {
        if (event.opportunity.opportunityId == null)
          crm.opportunities.add(result);
        else {
          int index = crm.opportunities.indexWhere((opportunity) =>
              opportunity.opportunityId == result.opportunityId);
          crm.opportunities.replaceRange(index, index + 1, [result]);
        }
        yield CrmLoaded(
            crm,
            'Opportunity ' +
                (event.opportunity?.opportunityId == null
                    ? 'Added'
                    : 'Updated'));
      } else {
        yield CrmProblem(result);
      }
    } else if (event is DeleteOpportunity) {
      yield CrmLoading("Deleting opportunity ${event.opportunity}");
      dynamic result =
          await repos.deleteOpportunity(event.opportunity.opportunityId);
      if (result == event.opportunity.opportunityId) {
        int index = crm.opportunities
            .indexWhere((opportunity) => opportunity.opportunityId == result);
        crm.opportunities.removeAt(index);
        yield CrmLoaded(crm, 'User ${event.opportunity} deleted');
      } else
        yield CrmProblem(result);
    } else
      yield CrmProblem("Event $event not defined!");
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
  final String imagePath;
  UpdateCrmUser(this.crmUser, this.imagePath);
  @override
  String toString() => 'Create/Update CrmUser { $crmUser }';
}

class DeleteCrmUser extends CrmEvent {
  final User crmUser;
  DeleteCrmUser(this.crmUser);
  @override
  String toString() => 'Delete CrmUser { $crmUser }';
}

class UpdateOpportunity extends CrmEvent {
  final Opportunity opportunity;
  UpdateOpportunity(this.opportunity);
  @override
  String toString() => 'Add/update opportunity { $opportunity }';
}

class DeleteOpportunity extends CrmEvent {
  final Opportunity opportunity;
  DeleteOpportunity(this.opportunity);
  @override
  String toString() => 'Delete opportunity { $opportunity }';
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
  final Crm crm;
  final String message;
  CrmLoaded(this.crm, [this.message]);
  @override
  String toString() => 'CrmLoaded { $crm }';
}
