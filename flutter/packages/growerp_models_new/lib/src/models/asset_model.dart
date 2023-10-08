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

import 'dart:convert';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

import '../create_csv_row.dart';
import 'models.dart';

part 'asset_model.g.dart';

@JsonSerializable()
class Asset {
  String assetId;
  String? assetClassId; // room; table etc
  String? assetName; // include room number/name
  String? statusId;
  Decimal? acquireCost;
  Decimal? quantityOnHand;
  Decimal? availableToPromise;
  String? parentAssetId;
  @DateTimeConverter()
  DateTime? receivedDate;
  @DateTimeConverter()
  DateTime? expectedEndOfLifeDate;
  Product? product;
  Location? location;
  String? acquireShipmentId;

  Asset({
    this.assetId = '',
    this.assetClassId, // room, table etc
    this.assetName, // include room number/name
    this.statusId,
    this.acquireCost,
    this.quantityOnHand,
    this.availableToPromise,
    this.parentAssetId,
    this.receivedDate,
    this.expectedEndOfLifeDate,
    this.product,
    this.location,
    this.acquireShipmentId,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
  Map<String, dynamic> toJson() => _$AssetToJson(this);

  @override
  String toString() => 'Asset name: $assetName[$assetId] '
      'Product: ${product?.productName}[${product?.productId}] '
      'QOH: $quantityOnHand Status: $statusId';
}

List<String> assetClassIds = [
  'Hotel Room',
  'Restaurant Table',
  'Restaurant Table Area'
];

List<String> assetStatusValues = ['Available', 'Deactivated', 'In Use'];
