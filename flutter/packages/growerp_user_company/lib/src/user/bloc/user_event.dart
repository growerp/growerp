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

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object> get props => [];
}

class UserFetch extends UserEvent {
  final UserGroup? userGroup;
  final String? partyId;
  final String searchString;
  final bool refresh;
  final int limit;

  const UserFetch({
    this.limit = 20,
    this.partyId,
    this.userGroup,
    this.searchString = '',
    this.refresh = false,
  });

  @override
  List<Object> get props => [searchString, refresh];
}

class UserUpdate extends UserEvent {
  final User user;
  const UserUpdate(this.user);
}

class UserDelete extends UserEvent {
  final User user;
  const UserDelete(this.user);
}

class UserSearchChanged extends UserEvent {
  const UserSearchChanged({
    required this.searchString,
    this.userGroup,
    this.partyId,
    this.limit = 20,
  });
  final String searchString;
  final UserGroup? userGroup;
  final String? partyId;
  final int limit;
  @override
  List<Object> get props => [searchString];
}
