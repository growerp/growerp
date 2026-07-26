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

part of 'gl_account_bloc.dart';

enum GlAccountStatus { initial, glAccountLoading, loading, success, failure }

class GlAccountState extends Equatable {
  const GlAccountState({
    this.status = GlAccountStatus.initial,
    this.glAccounts = const <GlAccount>[],
    this.accountClasses = const <AccountClass>[],
    this.accountTypes = const <AccountType>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final GlAccountStatus status;
  final String? message;
  final List<GlAccount> glAccounts;
  final List<AccountClass> accountClasses;
  final List<AccountType> accountTypes;
  final bool hasReachedMax;
  final String searchString;

  GlAccountState copyWith({
    GlAccountStatus? status,
    String? message,
    List<GlAccount>? glAccounts,
    List<AccountClass>? accountClasses,
    List<AccountType>? accountTypes,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return GlAccountState(
      status: status ?? this.status,
      glAccounts: glAccounts ?? this.glAccounts,
      accountClasses: accountClasses ?? this.accountClasses,
      accountTypes: accountTypes ?? this.accountTypes,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [
    message,
    glAccounts,
    accountClasses,
    accountTypes,
    status,
    hasReachedMax,
  ];

  @override
  String toString() =>
      '$status { #glAccounts: ${glAccounts.length}, '
      '#classes: ${accountClasses.length} #types: ${accountTypes.length} '
      'hasReachedMax: $hasReachedMax message $message}';
}
