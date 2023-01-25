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
import '../../../services/api_result.dart';
import '../../../services/network_exceptions.dart';
import '../../../api_repository.dart';
import '../models/models.dart';

part 'company_event.dart';
part 'company_state.dart';

const _companyLimit = 20;

EventTransformer<E> companyDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc(this.repos) : super(const CompanyState()) {
    on<CompanyFetch>(_onCompanyFetch,
        transformer: companyDroppable(const Duration(milliseconds: 100)));
    on<CompanyUpdate>(_onCompanyUpdate);
  }

  final APIRepository repos;
  Future<void> _onCompanyFetch(
    CompanyFetch event,
    Emitter<CompanyState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    try {
      // start from record zero for initial and refresh
      if (state.status == CompanyStatus.initial || event.refresh) {
        ApiResult<List<Company>> compResult =
            await repos.getCompanies(filter: event.searchString);
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: CompanyStatus.success,
                  companies: data,
                  hasReachedMax: data.length < _companyLimit ? true : false,
                  searchString: '',
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: CompanyStatus.failure, message: error.toString())));
      }
      // get first search page also for changed search
      if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
          (state.searchString.isNotEmpty &&
              event.searchString != state.searchString)) {
        ApiResult<List<Company>> compResult =
            await repos.getCompanies(filter: event.searchString);
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: CompanyStatus.success,
                  companies: data,
                  hasReachedMax: data.length < _companyLimit ? true : false,
                  searchString: event.searchString,
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: CompanyStatus.failure, message: error.toString())));
      }
      // get next page also for search

      ApiResult<List<Company>> compResult =
          await repos.getCompanies(filter: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: CompanyStatus.success,
                companies: List.of(state.companies)..addAll(data),
                hasReachedMax: data.length < _companyLimit ? true : false,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: CompanyStatus.failure, message: error.toString())));
    } catch (error) {
      emit(state.copyWith(
          status: CompanyStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onCompanyUpdate(
    CompanyUpdate event,
    Emitter<CompanyState> emit,
  ) async {
    try {
      List<Company> companies = List.from(state.companies);
      if (event.company.partyId != null) {
        ApiResult<Company> compResult =
            await repos.updateCompany(event.company);
        return emit(compResult.when(
            success: (data) {
              int index = companies.indexWhere(
                  (element) => element.partyId == event.company.partyId);
              companies[index] = data;
              return state.copyWith(
                  status: CompanyStatus.success,
                  companies: companies,
                  message: 'Company ${event.company.name} updated');
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: CompanyStatus.failure, message: error.toString())));
      } else {
        // add
        ApiResult<Company> compResult =
            await repos.createCompany(event.company);
        return emit(compResult.when(
            success: (data) {
              companies.insert(0, data);
              return state.copyWith(
                  status: CompanyStatus.success,
                  companies: companies,
                  message: 'Company ${event.company.name} added');
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: CompanyStatus.failure, message: error.toString())));
      }
    } catch (error) {
      emit(state.copyWith(
          status: CompanyStatus.failure, message: error.toString()));
    }
  }
}
