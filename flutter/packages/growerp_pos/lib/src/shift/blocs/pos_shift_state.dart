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

part of 'pos_shift_bloc.dart';

/// reported has its own value: a report fetched from the list must not close a
/// dialog that waits for success.
enum PosShiftStatus { initial, loading, success, reported, failure }

class PosShiftState extends Equatable {
  const PosShiftState({
    this.status = PosShiftStatus.initial,
    this.shift,
    this.report,
    this.shifts = const <PosShift>[],
    this.hasReachedMax = false,
    this.message,
  });

  final PosShiftStatus status;

  /// the open shift of this till, null when the till is closed
  final PosShift? shift;
  final PosZReport? report;
  final List<PosShift> shifts;
  final bool hasReachedMax;
  final String? message;

  PosShiftState copyWith({
    PosShiftStatus? status,
    PosShift? shift,
    PosZReport? report,
    List<PosShift>? shifts,
    bool? hasReachedMax,
    String? message,
  }) {
    return PosShiftState(
      status: status ?? this.status,
      shift: shift ?? this.shift,
      report: report ?? this.report,
      shifts: shifts ?? this.shifts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    shift,
    report,
    shifts,
    hasReachedMax,
    message,
  ];

  @override
  String toString() =>
      '$status { shift: ${shift?.shiftId}, #shifts: ${shifts.length} }';
}
