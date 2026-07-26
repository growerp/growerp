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

