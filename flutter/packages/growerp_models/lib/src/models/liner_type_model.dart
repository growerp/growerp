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
