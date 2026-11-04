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

enum PosFloorStatus { initial, success, failure }

class PosFloorState extends Equatable {
  const PosFloorState({
    this.status = PosFloorStatus.initial,
    this.tables = const <PosTable>[],
    this.message,
  });

  final PosFloorStatus status;
  final List<PosTable> tables;
  final String? message;

  PosFloorState copyWith({
    PosFloorStatus? status,
    List<PosTable>? tables,
    String? message,
  }) {
    return PosFloorState(
      status: status ?? this.status,
      tables: tables ?? this.tables,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, tables, message];

  @override
  String toString() => '$status { #tables: ${tables.length} }';
}
