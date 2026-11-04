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

abstract class PosShiftEvent extends Equatable {
  const PosShiftEvent();
  @override
  List<Object?> get props => [];
}

class PosShiftFetch extends PosShiftEvent {
  const PosShiftFetch(this.terminalName);
  final String terminalName;
  @override
  List<Object?> get props => [terminalName];
}

class PosShiftOpen extends PosShiftEvent {
  const PosShiftOpen({required this.terminalName, required this.openingFloat});
  final String terminalName;
  final Decimal openingFloat;
  @override
  List<Object?> get props => [terminalName, openingFloat];
}

/// positive into the drawer, negative out of it
class PosCashMovementAdd extends PosShiftEvent {
  const PosCashMovementAdd({required this.amount, this.reason});
  final Decimal amount;
  final String? reason;
  @override
  List<Object?> get props => [amount, reason];
}

class PosShiftClose extends PosShiftEvent {
  const PosShiftClose(this.countedCash);
  final Decimal countedCash;
  @override
  List<Object?> get props => [countedCash];
}

class PosShiftListFetch extends PosShiftEvent {
  const PosShiftListFetch({this.refresh = false, this.limit = 20});
  final bool refresh;
  final int limit;
  @override
  List<Object?> get props => [refresh, limit];
}

class PosZReportFetch extends PosShiftEvent {
  const PosZReportFetch(this.shiftId);
  final String shiftId;
  @override
  List<Object?> get props => [shiftId];
}
