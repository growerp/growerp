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
        hasReachedMax
      ];

  @override
  String toString() => '$status { #glAccounts: ${glAccounts.length}, '
      '#classes: ${accountClasses.length} #types: ${accountTypes.length} '
      'hasReachedMax: $hasReachedMax message $message}';
}
