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

enum CompanyUserStatus { initial, loading, filesLoading, success, failure }

class CompanyUserState extends Equatable {
  const CompanyUserState({
    this.status = CompanyUserStatus.initial,
    this.companiesUsers = const <CompanyUser>[],
    this.company,
    this.user,
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final CompanyUserStatus status;
  final String? message;
  final List<CompanyUser> companiesUsers;
  final Company? company;
  final User? user;
  final bool hasReachedMax;
  final String searchString;

  @override
  List<Object> get props => [status];

  @override
  String toString() => '$status { #companiesUsers: ${companiesUsers.length}, '
      'hasReachedMax: $hasReachedMax message $message} '
      'company: ${company?.name} user: ${user?.lastName}';

  CompanyUserState copyWith({
    CompanyUserStatus? status,
    String? message,
    List<CompanyUser>? companiesUsers,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
    Company? company,
    User? user,
  }) {
    return CompanyUserState(
      status: status ?? this.status,
      companiesUsers: companiesUsers ?? this.companiesUsers,
      company: company ?? this.company,
      user: user ?? this.user,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }
}
