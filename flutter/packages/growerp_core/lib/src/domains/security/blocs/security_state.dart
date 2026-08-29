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

enum SecurityStatus { initial, loading, success, failure }

class SecurityState extends Equatable {
  const SecurityState({
    this.status = SecurityStatus.initial,
    this.menuItems = const [],
    this.searchString = '',
    this.message,
  });

  final SecurityStatus status;

  /// Flattened tree: a top level screen followed by its tabs, in menu order.
  final List<SecurityRow> menuItems;
  final String searchString;
  final String? message;

  SecurityState copyWith({
    SecurityStatus? status,
    List<SecurityRow>? menuItems,
    String? searchString,
    String? message,
  }) {
    return SecurityState(
      status: status ?? this.status,
      menuItems: menuItems ?? this.menuItems,
      searchString: searchString ?? this.searchString,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, menuItems, searchString, message];

  @override
  String toString() =>
      'SecurityState { status: $status, rows: ${menuItems.length} }';
}

/// One row of the grid: a menu item plus how deep it sits in the menu.
class SecurityRow extends Equatable {
  const SecurityRow(this.item, this.depth);
  final MenuItem item;
  final int depth;
  @override
  List<Object?> get props => [item.menuItemId, depth];
}
