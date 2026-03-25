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

part 'liner_type_model.freezed.dart';
part 'liner_type_model.g.dart';

@freezed
abstract class LinerType with _$LinerType {
  factory LinerType({
    @Default("") String linerTypeId,
    String? linerName,
    Decimal? widthIncrement, // feet per strip
    Decimal? linerWeight, // lbs per sqft
    Decimal? rollStockWidth, // actual material width in feet
  }) = _LinerType;
  LinerType._();

  factory LinerType.fromJson(Map<String, dynamic> json) =>
      _$LinerTypeFromJson(json['linerType'] ?? json);

  @override
  String toString() => 'LinerType: $linerTypeId ($linerName)';
}
