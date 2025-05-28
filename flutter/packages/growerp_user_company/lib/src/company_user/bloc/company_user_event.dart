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

part of 'company_user_bloc.dart';

abstract class CompanyUserEvent extends Equatable {
  const CompanyUserEvent();
  @override
  List<Object> get props => [];
}

class CompanyUserFetch extends CompanyUserEvent {
  const CompanyUserFetch(
      {this.refresh = false,
      this.searchString = '',
      this.partyId,
      this.type,
      this.hasReachedMax = false,
      this.limit = 20,
      this.ownerPartyId = ''});
  final bool refresh;
  final String? partyId;
  final PartyType? type;
  final String ownerPartyId;
  final String searchString;
  final bool hasReachedMax;
  final int limit;
  @override
  List<Object> get props => [refresh, searchString, limit];
  @override
  String toString() =>
      "companyPartyId: $partyId, limit: $limit, owner: $ownerPartyId";
}

class CompanyUserUpdate extends CompanyUserEvent {
  final Company? company;
  final User? user;
  const CompanyUserUpdate({this.company, this.user});
  @override
  String toString() => "UpdateCompanyUser: $company $user";
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
