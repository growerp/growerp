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
import '../../../../services/json_converters.dart';
import '../../../domains.dart';

part 'asset_model.freezed.dart';
part 'asset_model.g.dart';

@freezed
class Asset with _$Asset {
  factory Asset({
    @Default("") String assetId,
    String? assetClassId, // room, table etc
    String? assetName, // include room number/name
    String? statusId,
    Decimal? acquireCost,
    Decimal? quantityOnHand,
    Decimal? availableToPromise,
    String? parentAssetId,
    @DateTimeConverter() DateTime? receivedDate,
    @DateTimeConverter() DateTime? expectedEndOfLifeDate,
    Product? product,
    Location? location,
    String? acquireShipmentId,
  }) = _Asset;
  Asset._();

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}

List<String> assetClassIds = [
  'Hotel Room',
  'Restaurant Table',
  'Restaurant Table Area'
];

List<String> assetStatusValues = ['Available', 'Deactivated', 'In Use'];
