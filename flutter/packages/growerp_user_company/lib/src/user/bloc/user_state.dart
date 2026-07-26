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
  String toString() =>
      '$status { #users: ${users.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
