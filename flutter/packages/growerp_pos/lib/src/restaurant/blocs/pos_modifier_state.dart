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

part of 'pos_modifier_bloc.dart';

enum PosModifierStatus { initial, success, failure }

class PosModifierState extends Equatable {
  const PosModifierState({
    this.status = PosModifierStatus.initial,
    this.groups = const <PosModifierGroup>[],
    this.message,
  });

  final PosModifierStatus status;
  final List<PosModifierGroup> groups;
  final String? message;

  PosModifierState copyWith({
    PosModifierStatus? status,
    List<PosModifierGroup>? groups,
    String? message,
  }) {
    return PosModifierState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, groups, message];

  @override
  String toString() => '$status { #groups: ${groups.length} }';
}
