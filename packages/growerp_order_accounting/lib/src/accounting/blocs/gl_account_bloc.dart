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
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:growerp_core/growerp_core.dart';

import '../../api_repository.dart';

part 'gl_account_event.dart';
part 'gl_account_state.dart';

const _accntLimit = 20;

EventTransformer<E> accntDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GlAccountBloc extends Bloc<GlAccountEvent, GlAccountState> {
  GlAccountBloc(this.repos) : super(const GlAccountState()) {
    on<GlAccountFetch>(_onGlAccountFetch,
        transformer: accntDroppable(const Duration(milliseconds: 100)));
  }

  final FinDocAPIRepository repos;

  Future<void> _onGlAccountFetch(
    GlAccountFetch event,
    Emitter<GlAccountState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    try {
      // start from record zero for initial and refresh
      if (state.status == GlAccountStatus.initial || event.refresh) {
        final compResult = await repos.getGlAccount();
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: GlAccountStatus.success,
                  glAccounts: data,
                  hasReachedMax: data.length < _accntLimit,
                  searchString: '',
                ),
            failure: (error) => state.copyWith(
                status: GlAccountStatus.failure,
                message: NetworkExceptions.getErrorMessage(error))));
      }
      // get first search page also for changed search
      if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
          (state.searchString.isNotEmpty &&
              event.searchString != state.searchString)) {
        final compResult = await repos.getGlAccount();
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: GlAccountStatus.success,
                  glAccounts: data,
                  hasReachedMax: data.length < _accntLimit,
                  searchString: event.searchString,
                ),
            failure: (error) => state.copyWith(
                status: GlAccountStatus.failure,
                message: NetworkExceptions.getErrorMessage(error))));
      }
      // get next page also for search

      final compResult = await repos.getGlAccount();
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: GlAccountStatus.success,
                glAccounts: List.of(state.glAccounts)..addAll(data),
                hasReachedMax: data.length < _accntLimit,
              ),
          failure: (error) => state.copyWith(
              status: GlAccountStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } on Exception catch (error) {
      emit(state.copyWith(
          status: GlAccountStatus.failure, message: error.toString()));
    }
  }
}
