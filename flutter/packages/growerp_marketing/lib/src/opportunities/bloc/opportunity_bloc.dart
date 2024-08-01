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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'opportunity_event.dart';
part 'opportunity_state.dart';

const _opportunityLimit = 20;

EventTransformer<E> opportunityDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class OpportunityBloc extends Bloc<OpportunityEvent, OpportunityState> {
  OpportunityBloc(this.restClient) : super(const OpportunityState()) {
    on<OpportunityFetch>(_onOpportunityFetch,
        transformer: opportunityDroppable(const Duration(milliseconds: 100)));
    on<OpportunityUpdate>(_onOpportunityUpdate);
    on<OpportunityDelete>(_onOpportunityDelete);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onOpportunityFetch(
    OpportunityFetch event,
    Emitter<OpportunityState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') {
      return;
    }
    if (state.status == OpportunityStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.opportunities.length;
    }
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: OpportunityStatus.loading));

      Opportunities compResult = await restClient.getOpportunity(
          start: start, searchString: event.searchString, limit: event.limit);

      if (event.searchString.isEmpty) {
        return emit(state.copyWith(
            status: OpportunityStatus.success,
            opportunities: start == 0
                ? compResult.opportunities
                : (List.of(state.opportunities)
                  ..addAll(compResult.opportunities)),
            hasReachedMax: compResult.opportunities.length < _opportunityLimit
                ? true
                : false,
            searchString: ''));
      } else {
        return emit(state.copyWith(
            status: OpportunityStatus.success,
            searchResults: compResult.opportunities,
            searchString: ''));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: OpportunityStatus.failure,
          opportunities: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onOpportunityUpdate(
    OpportunityUpdate event,
    Emitter<OpportunityState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OpportunityStatus.loading));
      List<Opportunity> opportunities = List.from(state.opportunities);
      if (event.opportunity.opportunityId.isNotEmpty) {
        Opportunity compResult =
            await restClient.updateOpportunity(opportunity: event.opportunity);
        int index = opportunities.indexWhere((element) =>
            element.opportunityId == event.opportunity.opportunityId);
        opportunities[index] = compResult;
        return emit(state.copyWith(
            status: OpportunityStatus.success,
            opportunities: opportunities,
            message:
                "opportunity ${event.opportunity.opportunityName} updated"));
      } else {
        // add
        Opportunity compResult =
            await restClient.createOpportunity(opportunity: event.opportunity);
        opportunities.insert(0, compResult);
        return emit(state.copyWith(
            status: OpportunityStatus.success,
            opportunities: opportunities,
            message: "opportunity ${event.opportunity.opportunityName} added"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: OpportunityStatus.failure,
          opportunities: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onOpportunityDelete(
    OpportunityDelete event,
    Emitter<OpportunityState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OpportunityStatus.loading));
      List<Opportunity> opportunities = List.from(state.opportunities);
      await restClient.deleteOpportunity(opportunity: event.opportunity);
      int index = opportunities.indexWhere((element) =>
          element.opportunityId == event.opportunity.opportunityId);
      opportunities.removeAt(index);
      return emit(state.copyWith(
          status: OpportunityStatus.success,
          opportunities: opportunities,
          message: "opportunity ${event.opportunity.opportunityName} deleted"));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: OpportunityStatus.failure,
          opportunities: [],
          message: getDioError(e)));
    }
  }
}
