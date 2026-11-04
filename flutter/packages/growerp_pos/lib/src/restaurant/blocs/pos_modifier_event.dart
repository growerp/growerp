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

abstract class PosModifierEvent extends Equatable {
  const PosModifierEvent();
  @override
  List<Object?> get props => [];
}

class PosModifierFetch extends PosModifierEvent {
  const PosModifierFetch();
}

class PosModifierSave extends PosModifierEvent {
  const PosModifierSave(this.group);
  final PosModifierGroup group;
  @override
  List<Object?> get props => [group];
}

class PosModifierDelete extends PosModifierEvent {
  const PosModifierDelete(this.groupId);
  final String groupId;
  @override
  List<Object?> get props => [groupId];
}
