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
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';
import 'package:rxdart/rxdart.dart';

class OpportunityBloc extends Bloc<OpportunityEvent, OpportunityState> {
  final repos;

  OpportunityBloc(this.repos) : super(OpportunityInitial());

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
    if (event is FetchOpportunity) {
      if (currentState is OpportunityInitial) {
        dynamic result = await repos.getOpportunity(
            start: 0, limit: event.limit, all: false);
        if (result is List<Opportunity>)
          yield OpportunitySuccess(
              opportunities: result,
              hasReachedMax: result.length < event.limit ? true : false);
        else
          yield OpportunityProblem(result);
        return;
      } else if (currentState is OpportunitySuccess) {
        if (event.search != null && currentState.search == null ||
            (currentState.search != null &&
                event.search != currentState.search)) {
          dynamic result = await repos.getOpportunity(
              start: 0, limit: event.limit, all: false, search: event.search);
          if (result is List<Opportunity>)
            yield OpportunitySuccess(
                opportunities: result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          else
            yield OpportunityProblem(result);
        } else if (!_hasReachedMax(currentState)) {
          dynamic result = await repos.getOpportunity(
              start: currentState.opportunities.length,
              limit: event.limit,
              all: false,
              search: event.search);
          if (result is List<Opportunity>) {
            yield currentState.copyWith(
                opportunities: currentState.opportunities + result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield OpportunityProblem(result);
        }
      }
    } else if (event is UpdateOpportunity) {
      bool adding = event.opportunity.opportunityId == null;
      yield OpportunityLoading((adding ? 'adding' : 'updating') +
          ' opportunity ${event.opportunity.opportunityName}');
      dynamic result = await repos.updateOpportunity(event.opportunity);
      if (currentState is OpportunitySuccess) {
        if (result is Opportunity) {
          if (adding) {
            currentState.opportunities?.add(result);
          } else {
            int index = currentState.opportunities
                .indexWhere((p) => p.opportunityId == result.opportunityId);
            currentState.opportunities.replaceRange(index, index + 1, [result]);
          }
          yield OpportunitySuccess(
                  opportunities: currentState.opportunities,
                  hasReachedMax: currentState.hasReachedMax)
              .copyWith(
                  message: 'Opportunity ' + (adding ? 'added' : 'updated'));
        } else {
          yield OpportunityProblem(result);
        }
      }
    } else if (event is DeleteOpportunity) {
      if (currentState is OpportunitySuccess) {
        String name = currentState.opportunities[event.index].opportunityName;
        yield OpportunityLoading('deleting opportunity $name');
        dynamic result = await repos.deleteOpportunity(
            currentState.opportunities[event.index].opportunityId);
        if (result == currentState.opportunities[event.index].opportunityId) {
          currentState.opportunities.removeAt(event.index);
          yield OpportunitySuccess(
                  opportunities: currentState.opportunities,
                  hasReachedMax: _hasReachedMax(currentState))
              .copyWith(message: 'Opportunity $name deleted');
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
  final String search;
  FetchOpportunity({this.limit = 20, this.search});
  @override
  String toString() => "FetchOpportunity limit: $limit, search: $search";
}

class DeleteOpportunity extends OpportunityEvent {
  final int index;
  DeleteOpportunity(this.index);
  @override
  String toString() => "DeleteOpportunity: $index";
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

class OpportunityLoading extends OpportunityState {
  final String message;
  OpportunityLoading([this.message]);
  @override
  List<Object> get props => [message];
  @override
  String toString() => 'Opportunity loading...';
}

class OpportunityProblem extends OpportunityState {
  final String errorMessage;
  OpportunityProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
  @override
  String toString() => 'OpportunityProblem { errorMessage $errorMessage }';
}

class OpportunitySuccess extends OpportunityState {
  final List<Opportunity> opportunities;
  final String message;
  final bool hasReachedMax;
  final String search;

  const OpportunitySuccess(
      {this.opportunities, this.message, this.hasReachedMax, this.search});

  OpportunitySuccess copyWith(
      {List<Opportunity> opportunities,
      String message,
      bool hasReachedMax,
      String search}) {
    return OpportunitySuccess(
        opportunities: opportunities ?? this.opportunities,
        message: message ?? this.message,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        search: search ?? this.search);
  }

  @override
  List<Object> get props => [opportunities, hasReachedMax, search];

  @override
  String toString() =>
      'OpportunitySuccess { #opportunities: ${opportunities.length}, '
      'hasReachedMax: $hasReachedMax }';
}
