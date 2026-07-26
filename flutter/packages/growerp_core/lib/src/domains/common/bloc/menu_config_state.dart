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

part of 'menu_config_bloc.dart';

enum MenuConfigStatus { initial, loading, success, failure }

class MenuConfigState extends Equatable {
  const MenuConfigState({
    this.status = MenuConfigStatus.initial,
    this.menuConfiguration,
    this.message,
  });

  final MenuConfigStatus status;
  final MenuConfiguration? menuConfiguration;
  final String? message;

  MenuConfigState copyWith({
    MenuConfigStatus? status,
    MenuConfiguration? menuConfiguration,
    String? message,
  }) {
    return MenuConfigState(
      status: status ?? this.status,
      menuConfiguration: menuConfiguration ?? this.menuConfiguration,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, menuConfiguration, message];

  @override
  String toString() {
    return '''MenuConfigState { status: $status, menuConfiguration: ${menuConfiguration?.name}, message: $message }''';
  }
}
