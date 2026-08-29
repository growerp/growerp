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

part of 'security_bloc.dart';

abstract class SecurityEvent extends Equatable {
  const SecurityEvent();
  @override
  List<Object?> get props => [];
}

/// Load every screen of [appId], including the ones the caller's own group
/// cannot use, so an admin can grant access to them.
class SecurityFetch extends SecurityEvent {
  const SecurityFetch({this.searchString = ''});
  final String searchString;
  @override
  List<Object?> get props => [searchString];
}

/// Set which groups may see and write through one screen.
class SecurityUpdate extends SecurityEvent {
  const SecurityUpdate({
    required this.menuItemId,
    required this.userGroups,
    required this.updateGroups,
  });
  final String menuItemId;
  final List<UserGroup> userGroups;
  final List<UserGroup> updateGroups;
  @override
  List<Object?> get props => [menuItemId, userGroups, updateGroups];
}
