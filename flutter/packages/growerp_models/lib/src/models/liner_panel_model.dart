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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'liner_panel_model.freezed.dart';
part 'liner_panel_model.g.dart';

@freezed
abstract class LinerPanel with _$LinerPanel {
  factory LinerPanel({
    @Default("") String qcNum,
    String? salesOrderId,
    String? workEffortId,
    String? linerTypeId,
    String? linerName,
    Decimal? panelWidth,
    Decimal? panelLength,
    Decimal? panelSqft, // server-computed: width * length
    Decimal? passes, // server-computed: width / widthIncrement - 1
    Decimal? weight, // server-computed: sqft * linerWeight
    String? panelName,
  }) = _LinerPanel;
  LinerPanel._();

  factory LinerPanel.fromJson(Map<String, dynamic> json) =>
      _$LinerPanelFromJson(json['linerPanel'] ?? json);

  @override
  String toString() =>
      'LinerPanel: $qcNum $panelName liner: $linerName ${panelWidth}x$panelLength';
}
