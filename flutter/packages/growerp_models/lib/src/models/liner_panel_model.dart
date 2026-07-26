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
