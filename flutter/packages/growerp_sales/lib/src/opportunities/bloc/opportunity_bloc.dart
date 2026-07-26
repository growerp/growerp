/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

part 'opportunity_event.dart';
part 'opportunity_state.dart';

const _opportunityLimit = 20;

EventTransformer<E> opportunityDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

const _opportunitySearchDebounceDuration = Duration(milliseconds: 300);
EventTransformer<OpportunitySearchChanged> opportunitySearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_opportunitySearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class OpportunityBloc extends Bloc<OpportunityEvent, OpportunityState> {
  OpportunityBloc(this.restClient) : super(const OpportunityState()) {
    on<OpportunityFetch>(
      _onOpportunityFetch,
      transformer: opportunityDroppable(const Duration(milliseconds: 100)),
    );
    on<OpportunitySummaryFetch>(_onOpportunitySummaryFetch);
    on<OpportunityUpdate>(_onOpportunityUpdate);
    on<OpportunityDelete>(_onOpportunityDelete);
    on<OpportunityConvertToOrder>(_onOpportunityConvertToOrder);
    on<OpportunitySearchChanged>(
      _onOpportunitySearchChanged,
      transformer: opportunitySearchDebounce(),
    );
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onOpportunitySearchChanged(
    OpportunitySearchChanged event,
    Emitter<OpportunityState> emit,
  ) async {
    return _onOpportunityFetch(
      OpportunityFetch(
        refresh: true,
        searchString: event.searchString,
        limit: event.limit,
      ),
      emit,
    );
  }

  Future<void> _onOpportunityFetch(
    OpportunityFetch event,
    Emitter<OpportunityState> emit,
  ) async {
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
        start: start,
        searchString: event.searchString,
        limit: event.limit,
      );

      if (event.searchString.isEmpty || event.refresh) {
        return emit(
          state.copyWith(
            status: OpportunityStatus.success,
            opportunities: start == 0
                ? compResult.opportunities
                : (List.of(state.opportunities)
                    ..addAll(compResult.opportunities)),
            hasReachedMax: compResult.opportunities.length < _opportunityLimit
                ? true
                : false,
            searchString: '',
          ),
        );
      } else {
        return emit(
          state.copyWith(
            status: OpportunityStatus.success,
            searchResults: compResult.opportunities,
            searchString: '',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: OpportunityStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onOpportunitySummaryFetch(
    OpportunitySummaryFetch event,
    Emitter<OpportunityState> emit,
  ) async {
    try {
      OpportunitySummary result = await restClient.getOpportunitySummary();
      emit(
        state.copyWith(
          status: OpportunityStatus.summarySuccess,
          summary: result.stageSummary,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: OpportunityStatus.failure,
          message: await getDioError(e),
        ),
      );
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
        Opportunity compResult = await restClient.updateOpportunity(
          opportunity: event.opportunity,
        );
        int index = opportunities.indexWhere(
          (element) => element.opportunityId == event.opportunity.opportunityId,
        );
        opportunities[index] = compResult;
        return emit(
          state.copyWith(
            status: OpportunityStatus.success,
            opportunities: opportunities,
            message: "opportunity ${event.opportunity.opportunityName} updated",
          ),
        );
      } else {
        // add
        Opportunity compResult = await restClient.createOpportunity(
          opportunity: event.opportunity,
        );
        opportunities.insert(0, compResult);
        return emit(
          state.copyWith(
            status: OpportunityStatus.success,
            opportunities: opportunities,
            message:
                'opportunityAddSuccess:${event.opportunity.opportunityName}',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: OpportunityStatus.failure,
          opportunities: [],
          message: await getDioError(e),
        ),
      );
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
      int index = opportunities.indexWhere(
        (element) => element.opportunityId == event.opportunity.opportunityId,
      );
      opportunities.removeAt(index);
      return emit(
        state.copyWith(
          status: OpportunityStatus.success,
          opportunities: opportunities,
          message:
              'opportunityDeleteSuccess:${event.opportunity.opportunityName}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: OpportunityStatus.failure,
          opportunities: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onOpportunityConvertToOrder(
    OpportunityConvertToOrder event,
    Emitter<OpportunityState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OpportunityStatus.loading));
      // Create a sales order (quote) in inPreparation status
      final FinDoc newOrder = await restClient.createFinDoc(
        finDoc: FinDoc(
          docType: FinDocType.order,
          sales: true,
          status: FinDocStatusVal.inPreparation,
          description: 'Quote for: ${event.opportunity.opportunityName}',
          otherUser: event.opportunity.leadUser,
          otherCompany: event.opportunity.leadUser?.company,
          grandTotal: event.opportunity.estAmount,
        ),
      );
      // Advance opportunity stage to Quote
      final Opportunity updatedOpportunity = await restClient.updateOpportunity(
        opportunity: event.opportunity.copyWith(stageId: 'Quote'),
      );
      List<Opportunity> opportunities = List.from(state.opportunities);
      final int index = opportunities.indexWhere(
        (e) => e.opportunityId == event.opportunity.opportunityId,
      );
      if (index >= 0) opportunities[index] = updatedOpportunity;
      return emit(
        state.copyWith(
          status: OpportunityStatus.success,
          opportunities: opportunities,
          convertedOrderId: newOrder.orderId,
          convertedPseudoId: newOrder.pseudoId,
          message: 'opportunityConvertSuccess:${newOrder.pseudoId}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: OpportunityStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
