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

part 'bom_item_model.freezed.dart';
part 'bom_item_model.g.dart';

@freezed
abstract class Bom with _$Bom {
  factory Bom({
    @Default("") String productId,
    @Default("") String productPseudoId,
    String? productName,
  }) = _Bom;
  Bom._();

  factory Bom.fromJson(Map<String, dynamic> json) =>
      _$BomFromJson(json['bom'] ?? json);

  @override
  String toString() => 'Bom: $productPseudoId ($productName)';
}

@freezed
abstract class BomItem with _$BomItem {
  factory BomItem({
    @Default("") String productId, // parent assembly product
    @Default("") String productPseudoId,
    String? productName,
    @Default("") String toProductId, // component product
    @Default("") String componentPseudoId,
    String? componentName,
    @Default("PatMfgBom") String productAssocTypeEnumId,
    String? fromDate,
    Decimal? quantity,
    Decimal? availableQuantity, // current inventory on hand for this component
    Decimal? unitCost,
    Decimal? totalCost,
    Decimal? scrapFactor,
    int? sequenceNum,
  }) = _BomItem;
  BomItem._();

  factory BomItem.fromJson(Map<String, dynamic> json) =>
      _$BomItemFromJson(json['bomItem'] ?? json);

  @override
  String toString() =>
      'BomItem: $productPseudoId -> $componentPseudoId qty: $quantity';
}

