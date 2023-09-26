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
import 'package:growerp_rest/growerp_rest.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../marketing_api_repository.dart';
import '../models/opportunity_model.dart';

part 'opportunity_event.dart';
part 'opportunity_state.dart';

const _opportunityLimit = 20;

EventTransformer<E> opportunityDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class OpportunityBloc extends Bloc<OpportunityEvent, OpportunityState> {
  OpportunityBloc(this.repos) : super(const OpportunityState()) {
    on<OpportunityFetch>(_onOpportunityFetch,
        transformer: opportunityDroppable(const Duration(milliseconds: 100)));
    on<OpportunityUpdate>(_onOpportunityUpdate);
    on<OpportunityDelete>(_onOpportunityDelete);
  }

  final MarketingAPIRepository repos;
  Future<void> _onOpportunityFetch(
    OpportunityFetch event,
    Emitter<OpportunityState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    // start from record zero for initial and refresh
    if (state.status == OpportunityStatus.initial || event.refresh) {
      ApiResult<List<Opportunity>> compResult =
          await repos.getOpportunity(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: OpportunityStatus.success,
                opportunities: data,
                hasReachedMax: data.length < _opportunityLimit ? true : false,
                searchString: '',
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: OpportunityStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<Opportunity>> compResult =
          await repos.getOpportunity(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: OpportunityStatus.success,
                opportunities: data,
                hasReachedMax: data.length < _opportunityLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: OpportunityStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search
    ApiResult<List<Opportunity>> compResult = await repos.getOpportunity(
        searchString: event.searchString,
        start: state.opportunities.length,
        limit: _opportunityLimit);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: OpportunityStatus.success,
              opportunities: List.of(state.opportunities)..addAll(data),
              hasReachedMax: data.length < _opportunityLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: OpportunityStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onOpportunityUpdate(
    OpportunityUpdate event,
    Emitter<OpportunityState> emit,
  ) async {
    List<Opportunity> opportunities = List.from(state.opportunities);
    if (event.opportunity.opportunityId.isNotEmpty) {
      ApiResult<Opportunity> compResult =
          await repos.updateOpportunity(event.opportunity);
      return emit(compResult.when(
          success: (data) {
            int index = opportunities.indexWhere((element) =>
                element.opportunityId == event.opportunity.opportunityId);
            opportunities[index] = data;
            return state.copyWith(
                status: OpportunityStatus.success,
                opportunities: opportunities,
                message:
                    "opportunity ${event.opportunity.opportunityName} updated");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: OpportunityStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      ApiResult<Opportunity> compResult =
          await repos.createOpportunity(event.opportunity);
      return emit(compResult.when(
          success: (data) {
            opportunities.insert(0, data);
            return state.copyWith(
                status: OpportunityStatus.success,
                opportunities: opportunities,
                message:
                    "opportunity ${event.opportunity.opportunityName} added");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: OpportunityStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }

  Future<void> _onOpportunityDelete(
    OpportunityDelete event,
    Emitter<OpportunityState> emit,
  ) async {
    List<Opportunity> opportunities = List.from(state.opportunities);
    ApiResult<Opportunity> compResult =
        await repos.deleteOpportunity(event.opportunity);
    return emit(compResult.when(
        success: (data) {
          int index = opportunities.indexWhere((element) =>
              element.opportunityId == event.opportunity.opportunityId);
          opportunities.removeAt(index);
          return state.copyWith(
              status: OpportunityStatus.success,
              opportunities: opportunities,
              message:
                  "opportunity ${event.opportunity.opportunityName} deleted");
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: OpportunityStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }
}
