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
import 'package:json_annotation/json_annotation.dart';

import 'models.dart';

part 'findoc_item_model.g.dart';

@JsonSerializable()
class FinDocItem {
  String? itemSeqId;
  ItemType? itemType;
  String? productId;
  String? description;
  Decimal? quantity;
  Decimal? price; // amount
  GlAccount? glAccount;
  bool? isDebit;
  String? assetId;
  String? assetName;
  Location? location;
  @DateTimeConverter()
  DateTime? rentalFromDate;
  @DateTimeConverter()
  DateTime? rentalThruDate;

  FinDocItem({
    this.itemSeqId,
    this.itemType,
    this.productId,
    this.description,
    this.quantity,
    this.price,
    this.glAccount,
    this.isDebit,
    this.assetId,
    this.assetName,
    this.location,
    this.rentalFromDate,
    this.rentalThruDate,
  });
  factory FinDocItem.fromJson(Map<String, dynamic> json) =>
      _$FinDocItemFromJson(json);
  Map<String, dynamic> toJson() => _$FinDocItemToJson(this);
}
