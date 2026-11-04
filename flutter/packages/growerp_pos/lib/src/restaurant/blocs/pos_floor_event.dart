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

part of 'pos_floor_bloc.dart';

abstract class PosFloorEvent extends Equatable {
  const PosFloorEvent();
  @override
  List<Object?> get props => [];
}

class PosFloorFetch extends PosFloorEvent {
  const PosFloorFetch();
}

/// create when the table has no id yet
class PosTableSave extends PosFloorEvent {
  const PosTableSave(this.table);
  final PosTable table;
  @override
  List<Object?> get props => [table];
}

class PosTableDelete extends PosFloorEvent {
  const PosTableDelete(this.assetId);
  final String assetId;
  @override
  List<Object?> get props => [assetId];
}
