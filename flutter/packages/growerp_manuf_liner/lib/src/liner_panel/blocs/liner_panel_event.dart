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

abstract class LinerPanelEvent extends Equatable {
  const LinerPanelEvent();
  @override
  List<Object?> get props => [];
}

class LinerPanelsFetch extends LinerPanelEvent {
  const LinerPanelsFetch({
    this.workEffortId,
    this.salesOrderId,
    this.refresh = false,
    this.limit = 100,
  });
  final String? workEffortId;
  final String? salesOrderId;
  final bool refresh;
  final int limit;
  @override
  List<Object?> get props => [workEffortId, salesOrderId, refresh];
}

class LinerPanelUpdate extends LinerPanelEvent {
  const LinerPanelUpdate(this.linerPanel);
  final LinerPanel linerPanel;
}

class LinerPanelDelete extends LinerPanelEvent {
  const LinerPanelDelete(this.linerPanel);
  final LinerPanel linerPanel;
}
