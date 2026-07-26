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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:equatable/equatable.dart';

part 'uom_model.freezed.dart';
part 'uom_model.g.dart';

@freezed
abstract class Uom extends Equatable with _$Uom {
  Uom._();
  factory Uom({
    @Default('') String uomId,
    @Default('') String uomTypeId,
    @Default('') String typeDescription,
    @Default('') String abbreviation,
    @Default('') String description,
  }) = _Uom;

  factory Uom.fromJson(Map<String, dynamic> json) =>
      _$UomFromJson(json['uomList'] ?? json);

  @override
  List<Object?> get props => [uomId];

  @override
  String toString() => '$description[$uomId]';
}
