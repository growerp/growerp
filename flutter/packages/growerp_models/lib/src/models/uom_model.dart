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
