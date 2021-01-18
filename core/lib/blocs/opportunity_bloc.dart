import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:rxdart/rxdart.dart';
import '../blocs/@blocs.dart';

const _opportunityLimit = 20;

class OpportunityBloc extends Bloc<OpportunityEvent, OpportunityState> {
  final repos;
  final LeadBloc leadBloc;
  StreamSubscription userBlocSubscription;
  List<User> leads;

  OpportunityBloc(this.repos, this.leadBloc) : super(OpportunityInitial()) {
    userBlocSubscription = leadBloc.listen((state) {
      if (state is UserFetchSuccess) {
        leads = state.users;
      }
    });
  }

  @override
  Future<void> close() {
    userBlocSubscription.cancel();
    return super.close();
  }

  @override
  Stream<Transition<OpportunityEvent, OpportunityState>> transformEvents(
    Stream<OpportunityEvent> events,
    TransitionFunction<OpportunityEvent, OpportunityState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  @override
  Stream<OpportunityState> mapEventToState(OpportunityEvent event) async* {
    final currentState = state;
    if (event is FetchOpportunity && !_hasReachedMax(currentState)) {
      if (currentState is OpportunityInitial) {
        dynamic result = await repos.getOpportunity(0, _opportunityLimit);
        if (result is List<Opportunity>) {
          yield OpportunitySuccess(
              opportunities: result,
              hasReachedMax: result.length < _opportunityLimit ? true : false,
              leads: leads);
        } else
          yield OpportunityProblem(result);
        return;
      }
      if (currentState is OpportunitySuccess) {
        dynamic result = await repos.getOpportunity(
            currentState.opportunities.length, event.limit);
        if (result is List<Opportunity>) {
          if (result.isEmpty) {
            yield currentState.copyWith(hasReachedMax: true);
          } else {
            yield OpportunitySuccess(
                opportunities: currentState.opportunities + result,
                hasReachedMax: false,
                leads: leads);
          }
        } else
          yield OpportunityProblem(result);
      }
    } else if (event is UpdateOpportunity) {
      dynamic result = await repos.updateOpportunity(event.opportunity);
      if (currentState is OpportunitySuccess) {
        if (result is Opportunity) {
          if (event.opportunity?.opportunityId == null) {
            currentState.opportunities?.add(event.opportunity);
          } else {
            int index = currentState.opportunities.indexWhere(
                (prod) => prod.opportunityId == result.opportunityId);
            currentState.opportunities
                .replaceRange(index, index + 1, [event.opportunity]);
          }
          yield OpportunitySuccess(
              opportunities: currentState.opportunities,
              hasReachedMax: _hasReachedMax(currentState));
        } else {
          yield OpportunityProblem(result);
        }
      }
    } else if (event is DeleteOpportunity) {
      dynamic result =
          await repos.deleteOpportunity(event.opportunity.opportunityId);
      if (currentState is OpportunitySuccess) {
        if (result == event.opportunity.opportunityId) {
          yield OpportunitySuccess(
              opportunities: currentState.opportunities,
              hasReachedMax: _hasReachedMax(currentState));
        } else {
          yield OpportunityProblem(result);
        }
      }
    }
  }
}

bool _hasReachedMax(OpportunityState state) =>
    state is OpportunitySuccess && state.hasReachedMax;

//#######################events###########################
abstract class OpportunityEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchOpportunity extends OpportunityEvent {
  final limit;
  FetchOpportunity([this.limit]);
  @override
  String toString() => "OpportunityFetched limit: $limit";
}

class DeleteOpportunity extends OpportunityEvent {
  final Opportunity opportunity;
  DeleteOpportunity(this.opportunity);
  @override
  String toString() => "DeleteOpportunity: $opportunity";
}

class UpdateOpportunity extends OpportunityEvent {
  final Opportunity opportunity;
  UpdateOpportunity(this.opportunity);
  @override
  String toString() => "UpdateOpportunity: $opportunity";
}

//#######################state############################
abstract class OpportunityState extends Equatable {
  const OpportunityState();

  @override
  List<Object> get props => [];
}

class OpportunityInitial extends OpportunityState {}

class OpportunityProblem extends OpportunityState {
  final String errorMessage;
  OpportunityProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
  @override
  String toString() => 'OpportunityProblem { errorMessage $errorMessage }';
}

class OpportunitySuccess extends OpportunityState {
  final Opportunity opportunity;
  final List<Opportunity> opportunities;
  final List<User> leads;
  final bool hasReachedMax;

  const OpportunitySuccess({
    this.opportunity,
    this.opportunities,
    this.leads,
    this.hasReachedMax,
  });

  OpportunitySuccess copyWith({
    List<Opportunity> opportunities,
    bool hasReachedMax,
  }) {
    return OpportunitySuccess(
      opportunities: opportunities ?? this.opportunities,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [opportunities, hasReachedMax];

  @override
  String toString() =>
      'OpportunitySuccess { #opportunities: ${opportunities.length}, '
      'opportunity: $opportunity hasReachedMax: $hasReachedMax }';
}
