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

part of 'user_bloc.dart';

enum UserStatus { initial, loading, success, failure }

class UserState extends Equatable {
  const UserState({
    this.status = UserStatus.initial,
    this.users = const <User>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final UserStatus status;
  final String? message;
  final List<User> users;
  final bool hasReachedMax;
  final String searchString;

  UserState copyWith({
    UserStatus? status,
    String? message,
    List<User>? users,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, users, hasReachedMax];

  @override
  String toString() => '$status { #users: ${users.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
