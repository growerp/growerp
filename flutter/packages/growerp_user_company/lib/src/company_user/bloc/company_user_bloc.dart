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

part 'company_user_event.dart';
part 'company_user_state.dart';

mixin CompanyUserLeadBloc on Bloc<CompanyUserEvent, CompanyUserState> {}
mixin CompanyUserCustomerBloc on Bloc<CompanyUserEvent, CompanyUserState> {}
mixin CompanyUserEmployeeBloc on Bloc<CompanyUserEvent, CompanyUserState> {}
mixin CompanyUserSupplierBloc on Bloc<CompanyUserEvent, CompanyUserState> {}

EventTransformer<E> companyUserDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class CompanyUserBloc extends Bloc<CompanyUserEvent, CompanyUserState>
    with CompanyUserLeadBloc, CompanyUserCustomerBloc, CompanyUserSupplierBloc {
  CompanyUserBloc(this.restClient, this.role)
      : super(const CompanyUserState()) {
    on<CompanyUserFetch>(_onCompanyUserFetch,
        transformer: companyUserDroppable(const Duration(milliseconds: 100)));
    on<CompanyUserUpdate>(_onCompanyUserUpdate);
    on<CompanyUserDelete>(_onCompanyUserDelete);
  }

  final RestClient restClient;
  Role role = Role.unknown;
  int start = 0;

  Future<void> _onCompanyUserFetch(
    CompanyUserFetch event,
    Emitter<CompanyUserState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    List<CompanyUser> current = [];
    if (state.status == CompanyUserStatus.initial ||
        event.refresh ||
        event.searchString.isNotEmpty) {
      start = 0;
      current = [];
    } else {
      start = state.companiesUsers.length;
      current = List.of(state.companiesUsers);
    }
    try {
      print(
          "==== company user fetch: start: $start limit: ${event.limit} reachMax: ${state.hasReachedMax}");
      emit(state.copyWith(status: CompanyUserStatus.loading));
      CompaniesUsers compResult = await restClient.getCompanyUser(
          role: role,
          searchString: event.searchString,
          start: start,
          limit: event.limit);
      emit(state.copyWith(
        status: CompanyUserStatus.success,
        companiesUsers: current..addAll(compResult.companiesUsers),
        hasReachedMax: compResult.companiesUsers.length < event.limit,
        searchString: event.searchString,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CompanyUserStatus.failure,
          companiesUsers: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onCompanyUserUpdate(
    CompanyUserUpdate event,
    Emitter<CompanyUserState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CompanyUserStatus.loading));
      List<CompanyUser> companiesUsers = List.from(state.companiesUsers);
      String message = '';
      if (event.companyUser.partyId != null) {
        // update
        if (event.companyUser.type == PartyType.company) {
          Company compResult = await restClient.updateCompany(
              company: event.companyUser.getCompany()!);
          if (companiesUsers.isNotEmpty) {
            int index = companiesUsers.indexWhere(
                (element) => element.partyId == event.companyUser.partyId);
            companiesUsers[index] = CompanyUser.tryParse(compResult)!;
          } else {
            companiesUsers.add(CompanyUser.tryParse(compResult)!);
          }
          message = 'Company ${compResult.name} updated...';
        }
        if (event.companyUser.type == PartyType.user) {
          User compResult =
              await restClient.updateUser(user: event.companyUser.getUser()!);
          if (companiesUsers.isNotEmpty) {
            int index = companiesUsers.indexWhere(
                (element) => element.partyId == event.companyUser.partyId);
            companiesUsers[index] = CompanyUser.tryParse(compResult)!;
          } else {
            companiesUsers.add(CompanyUser.tryParse(compResult)!);
          }
          message =
              'user ${compResult.firstName} ${compResult.lastName} updated...';
        }
        return emit(state.copyWith(
            searchString: '',
            status: CompanyUserStatus.success,
            companiesUsers: companiesUsers,
            message: message));
      } else {
        // add
        if (event.companyUser.type == PartyType.company) {
          Company compResult = await restClient.createCompany(
              company: event.companyUser.getCompany()!);
          companiesUsers.insert(0, CompanyUser.tryParse(compResult)!);
          message = 'CompanyUser ${event.companyUser.name} added';
        }
        if (event.companyUser.type == PartyType.company) {
          User compResult =
              await restClient.createUser(user: event.companyUser.getUser()!);
          companiesUsers.insert(0, CompanyUser.tryParse(compResult)!);
        }
      }
      return emit(state.copyWith(
          status: CompanyUserStatus.success,
          companiesUsers: companiesUsers,
          message: 'CompanyUser ${event.companyUser.name} added'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CompanyUserStatus.failure,
          companiesUsers: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onCompanyUserDelete(
    CompanyUserDelete event,
    Emitter<CompanyUserState> emit,
  ) async {}
}
