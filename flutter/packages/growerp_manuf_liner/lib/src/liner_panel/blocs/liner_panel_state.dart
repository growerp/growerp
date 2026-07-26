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

part of 'liner_panel_bloc.dart';

enum LinerPanelStatus { initial, loading, success, failure }

class LinerPanelState extends Equatable {
  const LinerPanelState({
    this.status = LinerPanelStatus.initial,
    this.linerPanels = const <LinerPanel>[],
    this.message,
    this.hasReachedMax = false,
    this.workEffortId,
    this.salesOrderId,
  });

  final LinerPanelStatus status;
  final String? message;
  final List<LinerPanel> linerPanels;
  final bool hasReachedMax;
  final String? workEffortId;
  final String? salesOrderId;

  LinerPanelState copyWith({
    LinerPanelStatus? status,
    String? message,
    List<LinerPanel>? linerPanels,
    bool? hasReachedMax,
    String? workEffortId,
    String? salesOrderId,
  }) {
    return LinerPanelState(
      status: status ?? this.status,
      linerPanels: linerPanels ?? this.linerPanels,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      workEffortId: workEffortId ?? this.workEffortId,
      salesOrderId: salesOrderId ?? this.salesOrderId,
    );
  }

  @override
  List<Object?> get props => [linerPanels, hasReachedMax, status, workEffortId];

  @override
  String toString() =>
      '$status { #linerPanels: ${linerPanels.length}, '
      'workEffortId: $workEffortId, hasReachedMax: $hasReachedMax }';
}
