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

part 'company_event.dart';
part 'company_state.dart';

mixin CompanyLeadBloc on Bloc<CompanyEvent, CompanyState> {}
mixin CompanyCustomerBloc on Bloc<CompanyEvent, CompanyState> {}
mixin CompanyEmployeeBloc on Bloc<CompanyEvent, CompanyState> {}
mixin CompanySupplierBloc on Bloc<CompanyEvent, CompanyState> {}

EventTransformer<E> companyDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class CompanyBloc extends Bloc<CompanyEvent, CompanyState>
    with CompanyLeadBloc, CompanyCustomerBloc, CompanySupplierBloc {
  CompanyBloc(this.restClient, this.role) : super(const CompanyState()) {
    on<CompanyFetch>(_onCompanyFetch,
        transformer: companyDroppable(const Duration(milliseconds: 100)));
    on<CompanyUpdate>(_onCompanyUpdate);
    on<CompanyDelete>(_onCompanyDelete);
  }

  final RestClient restClient;
  final Role? role;
  int start = 0;

  Future<void> _onCompanyFetch(
      CompanyFetch event, Emitter<CompanyState> emit) async {
    List<Company> current = [];
    if (state.status == CompanyStatus.initial ||
        event.refresh ||
        event.searchString.isNotEmpty) {
      start = 0;
      current = [];
    } else {
      start = state.companies.length;
      current = List.of(state.companies);
    }
    try {
      emit(state.copyWith(status: CompanyStatus.loading));
      late Companies compResult;
      if (event.mainOnly) {
        compResult =
            await restClient.getCompanies(start: start, limit: event.limit);
      } else {
        compResult = await restClient.getCompany(
            role: role,
            companyPartyId: event.companyPartyId,
            ownerPartyId: event.ownerPartyId,
            searchString: event.searchString,
            isForDropDown: event.isForDropDown,
            start: start,
            limit: event.limit);
        emit(state.copyWith(
          status: CompanyStatus.success,
          companies: current..addAll(compResult.companies),
          hasReachedMax: compResult.companies.length < event.limit,
          searchString: event.searchString,
        ));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CompanyStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onCompanyUpdate(
    CompanyUpdate event,
    Emitter<CompanyState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CompanyStatus.loading));
      List<Company> companies = List.from(state.companies);
      if (event.company.partyId != null) {
        Company compResult =
            await restClient.updateCompany(company: event.company);
        if (companies.isNotEmpty) {
          int index = companies.indexWhere(
              (element) => element.partyId == event.company.partyId);
          companies.removeAt(index);
          companies.insert(0, compResult);
        } else {
          companies.add(compResult);
        }
        // this update can be achieved by logging out and in again.
//        if (authBloc.state.authenticate!.company!.partyId ==
//            compResult.partyId) {
//        authBloc.add(AuthLoad());
//        }
        return emit(state.copyWith(
            status: CompanyStatus.success,
            companies: companies,
            message: 'Company ${event.company.name} updated'));
      } else {
        // add
        Company compResult =
            await restClient.createCompany(company: event.company);
        companies.insert(0, compResult);
        return emit(state.copyWith(
            status: CompanyStatus.success,
            companies: companies,
            message: 'Company ${event.company.name} added'));
      }
    } on DioException catch (e) {
      return emit(state.copyWith(
          status: CompanyStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onCompanyDelete(
    CompanyDelete event,
    Emitter<CompanyState> emit,
  ) async {}
}
