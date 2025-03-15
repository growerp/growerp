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
import 'package:flutter/foundation.dart';
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
      emit(state.copyWith(status: CompanyUserStatus.loading));
      if (event.type == PartyType.company && event.partyId != null) {
        Companies compUserResult =
            await restClient.getCompany(companyPartyId: event.partyId);
        return emit(state.copyWith(
            status: CompanyUserStatus.success,
            company: compUserResult.companies.isNotEmpty
                ? compUserResult.companies[0]
                : null));
      }
      if (event.type == PartyType.user && event.partyId != null) {
        Users userResult = await restClient.getUser(partyId: event.partyId);
        return emit(state.copyWith(
            status: CompanyUserStatus.success,
            user: userResult.users.isNotEmpty ? userResult.users[0] : null));
      }
      final CompaniesUsers compUserResult = await restClient.getCompanyUser(
          role: role,
          searchString: event.searchString,
          start: start,
          limit: event.limit);

      return emit(state.copyWith(
        status: CompanyUserStatus.success,
        companiesUsers: current..addAll(compUserResult.companiesUsers),
        hasReachedMax: compUserResult.companiesUsers.length < event.limit,
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
      if (event.company != null) {
        Company compResult;
        if (event.company?.partyId != null) {
          // update company
          compResult = await restClient.updateCompany(company: event.company!);
          int index = companiesUsers.indexWhere(
              (element) => element.partyId == event.company!.partyId);
          if (index == -1) {
            debugPrint(
                "===could not find partyId; ${event.company!.partyId} in list: $companiesUsers");
          } else {
            companiesUsers[index] = CompanyUser.tryParse(compResult)!;
            message = 'Company ${compResult.name} updated...';
          }
        } else {
          // add company
          compResult = await restClient.createCompany(company: event.company!);
          companiesUsers.insert(0, CompanyUser.tryParse(compResult)!);
          message = 'Company ${compResult.name} added';
        }
        return emit(state.copyWith(
            status: CompanyUserStatus.success,
            company: compResult,
            companiesUsers: companiesUsers,
            message: message));
      }
      if (event.user != null) {
        User userResult;
        if (event.user?.partyId != null) {
          // update user
          userResult = await restClient.updateUser(user: event.user!);
          if (companiesUsers.isNotEmpty) {
            int index = companiesUsers.indexWhere(
                (element) => element.partyId == event.user?.partyId);
            companiesUsers[index] = CompanyUser.tryParse(userResult)!;
          } else {
            companiesUsers.add(CompanyUser.tryParse(userResult)!);
          }
          message =
              'user ${userResult.firstName} ${userResult.lastName} updated...';
        } else {
          // add user
          userResult = await restClient.createUser(user: event.user!);
          companiesUsers.insert(0, CompanyUser.tryParse(userResult)!);
          message =
              'user ${userResult.firstName} ${userResult.lastName} Added...';
        }
        return emit(state.copyWith(
            status: CompanyUserStatus.success,
            user: userResult,
            companiesUsers: companiesUsers,
            message: message));
      }
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
