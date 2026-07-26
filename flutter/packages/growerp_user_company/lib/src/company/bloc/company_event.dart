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

part of 'company_bloc.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();
  @override
  List<Object> get props => [];
}

class CompanyFetch extends CompanyEvent {
  const CompanyFetch({
    this.refresh = false,
    this.searchString = '',
    this.companyPartyId = '',
    this.limit = 20,
    this.isForDropDown = false,
    this.ownerPartyId = '',
    this.mainOnly = false,
  });
  final bool refresh;
  final String companyPartyId;
  final String ownerPartyId;
  final String searchString;
  final int limit;
  final bool isForDropDown;
  final bool mainOnly;
  @override
  List<Object> get props => [refresh, searchString, limit];
  @override
  String toString() =>
      "companyPartyId: $companyPartyId, limit: $limit, owner: $ownerPartyId, isforDropDown: $isForDropDown";
}

class CompanyUpdate extends CompanyEvent {
  final Company company;
  const CompanyUpdate(this.company);
  @override
  String toString() => "UpdateCompany: $company";
}

class CompanyDelete extends CompanyEvent {
  final Company company;
  const CompanyDelete(this.company);
  @override
  String toString() => "UpdateCompany: $company";
}

class CompanySearchChanged extends CompanyEvent {
  const CompanySearchChanged({
    required this.searchString,
    this.mainOnly = false,
    this.limit = 20,
  });
  final String searchString;
  final bool mainOnly;
  final int limit;
  @override
  List<Object> get props => [searchString];
}
