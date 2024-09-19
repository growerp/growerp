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
      this.partyId = '',
      this.type,
      this.hasReachedMax = false,
      this.limit = 20,
      this.ownerPartyId = ''});
  final bool refresh;
  final String partyId;
  final PartyType? type;
  final String ownerPartyId;
  final String searchString;
  final bool hasReachedMax;
  final int limit;
  @override
  List<Object> get props =>
      [refresh, searchString, limit, type.toString(), partyId];
  @override
  String toString() =>
      "companyPartyId: $partyId, limit: $limit, owner: $ownerPartyId";
}

class CompanyUserUpdate extends CompanyUserEvent {
  final CompanyUser companyUser;
  const CompanyUserUpdate(this.companyUser);
  @override
  String toString() => "UpdateCompanyUser: $companyUser";
}

class CompanyUserDelete extends CompanyUserEvent {
  final CompanyUser company;
  const CompanyUserDelete(this.company);
  @override
  String toString() => "UpdateCompanyUser: $company";
}
