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

//======================please not a similar
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
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
    on<CompanyUserFetch>(
      _onCompanyUserFetch,
      transformer: companyUserDroppable(const Duration(milliseconds: 100)),
    );
    on<CompanyUserUpdate>(_onCompanyUserUpdate);
    on<CompanyUserDelete>(_onCompanyUserDelete);
    on<CompanyUserUpload>(_onCompanyUserUpload);
    on<CompanyUserDownload>(_onCompanyUserDownload);
  }

  final RestClient restClient;
  Role role = Role.unknown;
  int start = 0;

  Future<void> _onCompanyUserFetch(
    CompanyUserFetch event,
    Emitter<CompanyUserState> emit,
  ) async {
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
        Companies compUserResult = await restClient.getCompany(
          companyPartyId: event.partyId,
        );
        return emit(
          state.copyWith(
            status: CompanyUserStatus.success,
            company: compUserResult.companies.isNotEmpty
                ? compUserResult.companies[0]
                : null,
          ),
        );
      }
      if (event.type == PartyType.user && event.partyId != null) {
        Users userResult = await restClient.getUser(partyId: event.partyId);
        return emit(
          state.copyWith(
            status: CompanyUserStatus.success,
            user: userResult.users.isNotEmpty ? userResult.users[0] : null,
          ),
        );
      }
      final CompaniesUsers compUserResult = await restClient.getCompanyUser(
        role: role,
        searchString: event.searchString,
        start: start,
        limit: event.limit,
      );

      return emit(
        state.copyWith(
          status: CompanyUserStatus.success,
          companiesUsers: current..addAll(compUserResult.companiesUsers),
          hasReachedMax: compUserResult.companiesUsers.length < event.limit,
          searchString: event.searchString,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CompanyUserStatus.failure,
          message: await getDioError(e),
        ),
      );
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
      CompanyUser companyUser;
      if (event.companyUser?.type == PartyType.company) {
        Company result;
        if (event.companyUser?.partyId != null) {
          // update company
          result = await restClient.updateCompany(
            company: event.companyUser!.getCompany()!,
          );
          int index = companiesUsers.indexWhere(
            (element) => element.partyId == event.companyUser!.partyId,
          );
          if (index == -1) {
            debugPrint(
              "===could not find partyId; ${event.companyUser!.partyId} in list: $companiesUsers",
            );
          } else {
            companiesUsers.removeAt(index);
            companiesUsers.insert(0, CompanyUser.tryParse(result)!);
            message = 'companyUpdateSuccess:${result.name}';
          }
        } else {
          // add company
          result = await restClient.createCompany(
            company: event.companyUser!.getCompany()!,
          );
          companiesUsers.insert(0, CompanyUser.tryParse(result)!);
          message = 'companyAddSuccess:${result.name}';
        }
      } else {
        if (event.companyUser?.company?.name != null) {
          // when a user is added with a company the backend will
          // just show the company with a user (employee)
          // since we just show the local entered data,
          // (the backend will not do that for the company)
          // we should do that here too.
          var obj = event.companyUser;
          companyUser = CompanyUser(
            role: obj!.role,
            type: PartyType.company,
            name: obj.company?.name,
            email: obj.company?.email,
            url: obj.company?.url,
            telephoneNr: obj.company?.telephoneNr,
            image: obj.company?.image,
            paymentMethod: obj.company?.paymentMethod,
            address: obj.company?.address,
            employees: [event.companyUser?.getUser() ?? User()],
          );
        } else {
          companyUser = event.companyUser!;
        }
        // user add/update
        User result;
        if (event.companyUser?.partyId != null) {
          // update user
          result = await restClient.updateUser(
            user: event.companyUser!.getUser()!,
          );
          int index = companiesUsers.indexWhere(
            (element) => element.partyId == event.companyUser!.partyId,
          );
          if (index == -1) {
            debugPrint(
              "===could not find partyId; ${event.companyUser!.partyId} in list: $companiesUsers",
            );
          } else {
            companiesUsers.removeAt(index);
            message = 'userUpdateSuccess:${companyUser.name}';
          }
        } else {
          // add user
          result = await restClient.createUser(
            user: event.companyUser!.getUser()!,
          );
          message = 'userAddSuccess:${companyUser.name}';
        }
        // now depending if the company/user is reversed pick the correct id.
        if (event.companyUser?.company?.name == null) {
          companiesUsers.insert(
            0,
            companyUser.copyWith(
              pseudoId: result.pseudoId,
              partyId: result.partyId,
            ),
          );
        } else {
          companiesUsers.insert(
            0,
            companyUser.copyWith(
              pseudoId: result.company?.pseudoId,
              partyId: result.company?.partyId,
              employees: [
                companyUser.employees?[0].copyWith(
                      pseudoId: result.pseudoId,
                      partyId: result.partyId,
                    ) ??
                    User(),
              ],
            ),
          );
        }
      }

      return emit(
        state.copyWith(
          status: CompanyUserStatus.success,
          companiesUsers: companiesUsers,
          message: message,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CompanyUserStatus.failure,
          companiesUsers: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCompanyUserUpload(
    CompanyUserUpload event,
    Emitter<CompanyUserState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CompanyUserStatus.filesLoading));
      List<CompanyUser> companyUsers = [];
      final result = fast_csv.parse(event.file);
      int line = 0;
      // import csv into companyUsers
      for (final row in result) {
        if (line++ < 2 || row.length < 12) continue;
        companyUsers.add(
          CompanyUser(
            pseudoId: row[0],
            type: PartyType.tryParse(row[1]),
            name: row[2],
            role: Role.tryParse(row[3]),
            email: row[4],
            url: row[5],
            telephoneNr: row[6],
            address: Address(
              address1: row[7],
              address2: row[8],
              postalCode: row[09],
              city: row[10],
              province: row[11],
              country: row[12],
              countryId: row[13],
            ),
            company: Company(pseudoId: row[13], name: row[14]),
          ),
        );
      }
      await restClient.importCompanyUsers(companyUsers);
      return emit(
        state.copyWith(
          status: CompanyUserStatus.success,
          companiesUsers: state.companiesUsers,
          message: 'compUserUploadSuccess',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CompanyUserStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCompanyUserDownload(
    CompanyUserDownload event,
    Emitter<CompanyUserState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CompanyUserStatus.filesLoading));
      await restClient.exportScreenCompanyUsers();
      emit(
        state.copyWith(
          status: CompanyUserStatus.success,
          companiesUsers: state.companiesUsers,
          message: 'compUserDownloadSuccess',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CompanyUserStatus.failure,
          companiesUsers: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCompanyUserDelete(
    CompanyUserDelete event,
    Emitter<CompanyUserState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CompanyUserStatus.loading));
      List<CompanyUser> companiesUsers = List.from(state.companiesUsers);
      await restClient.deleteUser(
        partyId: event.user!.partyId!,
        deleteCompanyToo: false,
      );
      int index = companiesUsers.indexWhere(
        (element) => element.partyId == event.user!.partyId,
      );
      companiesUsers.removeAt(index);
      return emit(
        state.copyWith(
          searchString: '',
          status: CompanyUserStatus.success,
          companiesUsers: companiesUsers,
          message: 'userDeleteSuccess:${event.user!.getName()}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CompanyUserStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
