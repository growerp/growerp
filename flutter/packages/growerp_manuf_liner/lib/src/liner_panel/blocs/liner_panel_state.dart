/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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
