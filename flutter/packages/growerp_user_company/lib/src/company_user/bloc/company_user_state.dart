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
  String toString() =>
      '$status { #companiesUsers: ${companiesUsers.length}, '
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
