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

part of 'company_bloc.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();
  @override
  List<Object> get props => [];
}

class CompanyFetch extends CompanyEvent {
  CompanyFetch({this.refresh = false, this.searchString = ''});
  final bool refresh;
  final String searchString;
  @override
  List<Object> get props => [refresh, searchString];
}

class CompanyUpdate extends CompanyEvent {
  final Company company;
  CompanyUpdate(this.company);
  @override
  String toString() => "UpdateCompany: $company";
}
