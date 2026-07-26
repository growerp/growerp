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

part of 'company_user_bloc.dart';

abstract class CompanyUserEvent extends Equatable {
  const CompanyUserEvent();
  @override
  List<Object> get props => [];
}

class CompanyUserFetch extends CompanyUserEvent {
  const CompanyUserFetch({
    this.refresh = false,
    this.searchString = '',
    this.partyId,
    this.type,
    this.hasReachedMax = false,
    this.limit = 20,
    this.ownerPartyId = '',
    this.isForDropDown = false,
  });
  final bool refresh;
  final String? partyId;
  final PartyType? type;
  final String ownerPartyId;
  final String searchString;
  final bool hasReachedMax;
  final bool isForDropDown;
  final int limit;
  @override
  List<Object> get props => [refresh, searchString, limit];
  @override
  String toString() =>
      "companyPartyId: $partyId, limit: $limit, owner: $ownerPartyId";
}

class CompanyUserUpdate extends CompanyUserEvent {
  final CompanyUser? companyUser;
  const CompanyUserUpdate(this.companyUser);
  @override
  String toString() => "UpdateCompanyUser: $companyUser";
}

class CompanyUserDelete extends CompanyUserEvent {
  final Company? company;
  final User? user;
  const CompanyUserDelete({this.company, this.user});
  @override
  String toString() => "Update Company/User: $company $user";
}

/// initiate a download of products by email.
class CompanyUserDownload extends CompanyUserEvent {}

/// start a [CompanyUser] import
class CompanyUserUpload extends CompanyUserEvent {
  const CompanyUserUpload(this.file);
  final String file;
}

class CompanyUserSearchChanged extends CompanyUserEvent {
  const CompanyUserSearchChanged({
    required this.searchString,
    this.limit = 20,
  });
  final String searchString;
  final int limit;
  @override
  List<Object> get props => [searchString];
}
