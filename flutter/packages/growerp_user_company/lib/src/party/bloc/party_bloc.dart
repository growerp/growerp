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
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'party_event.dart';
part 'party_state.dart';

mixin LeadBloc on Bloc<PartyEvent, PartyState> {}
mixin CustomerBloc on Bloc<PartyEvent, PartyState> {}
mixin EmployeeBloc on Bloc<PartyEvent, PartyState> {}
mixin SupplierBloc on Bloc<PartyEvent, PartyState> {}

EventTransformer<E> partyDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PartyBloc extends Bloc<PartyEvent, PartyState>
    with LeadBloc, CustomerBloc, EmployeeBloc, SupplierBloc {
  PartyBloc(this.restClient, this.role) : super(const PartyState()) {
    on<PartyFetch>(_onPartyFetch,
        transformer: partyDroppable(const Duration(milliseconds: 100)));
    on<PartyUpdate>(_onPartyUpdate);
    on<PartyDelete>(_onPartyDelete);
  }

  final RestClient restClient;
  final Role? role;
  int start = 0;

  Future<void> _onPartyFetch(
    PartyFetch event,
    Emitter<PartyState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') {
      return;
    }
    if (state.status == PartyStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.parties.length;
    }
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: PartyStatus.loading));

      Parties compResult = await restClient.getParty(
          start: start,
          limit: event.limit,
          role: role,
          searchString: event.searchString);

      return emit(state.copyWith(
        status: PartyStatus.success,
        parties: start == 0
            ? compResult.parties
            : (List.of(state.parties)..addAll(compResult.parties)),
        hasReachedMax: compResult.parties.length < event.limit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: PartyStatus.failure, parties: [], message: getDioError(e)));
    }
  }

  Future<void> _onPartyUpdate(
    PartyUpdate event,
    Emitter<PartyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PartyStatus.loading));
      List<Party> parties = List.from(state.parties);
      if (event.party.partyId != null) {
        // update
        Party compResult = await restClient.updateParty(party: event.party);
        if (parties.isNotEmpty) {
          int index = parties
              .indexWhere((element) => element.partyId == event.party.partyId);
          parties[index] = compResult;
        } else {
          parties.add(compResult);
        }
        return emit(state.copyWith(
            searchString: '',
            status: PartyStatus.success,
            parties: parties,
            message:
                'party ${compResult.firstName} ${compResult.lastName} updated...'));
      } else {
        // add
        Party compResult = await restClient.createParty(party: event.party);
        parties.insert(0, compResult);
        return emit(state.copyWith(
            searchString: '',
            status: PartyStatus.success,
            parties: parties,
            message:
                'party ${compResult.firstName} ${compResult.lastName} added...'));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: PartyStatus.failure, parties: [], message: getDioError(e)));
    }
  }

  Future<void> _onPartyDelete(
    PartyDelete event,
    Emitter<PartyState> emit,
  ) async {
    try {
      List<Party> parties = List.from(state.parties);
      await restClient.deleteParty(
          partyId: event.party.partyId!, deleteCompanyToo: false);
      int index = parties
          .indexWhere((element) => element.partyId == event.party.partyId);
      parties.removeAt(index);
      return emit(state.copyWith(
          searchString: '',
          status: PartyStatus.success,
          parties: parties,
          message: 'Party ${event.party.firstName} is deleted now..'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: PartyStatus.failure, parties: [], message: getDioError(e)));
    }
  }
}
