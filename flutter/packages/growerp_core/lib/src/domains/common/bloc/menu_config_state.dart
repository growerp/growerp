/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
