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

import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:logger/logger.dart';

import '../../growerp_models.dart';

part 'asset_model.freezed.dart';
part 'asset_model.g.dart';

@freezed
abstract class Asset with _$Asset {
  factory Asset({
    @Default("") String assetId,
    @Default("") String pseudoId,
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

  factory Asset.fromJson(Map<String, dynamic> json) =>
      _$AssetFromJson(json['asset'] ?? json);

  @override
  String toString() =>
      'Asset name: $assetName[$assetId] '
      'Product: ${product?.productName}[${product?.productId}] '
      'QOH: $quantityOnHand Status: $statusId';
}

List<String> assetClassIds = [
  'Hotel Room',
  'Restaurant Table',
  'Restaurant Table Area',
  'Equipment',
];

List<String> assetStatusValues = ['Available', 'Deactivated', 'In Use'];

String assetCsvFormat =
    'AssetClassId, Asset Name, AquiredCost, QOH, ATP, ReceivedDate, '
    'EndOfLifeDate, ProductId, LocationId,\r\n';
List<String> assetCsvTitles = assetCsvFormat.split(',');
int assetCsvLength = assetCsvTitles.length;

List<Asset> csvToAssets(String csvFile, Logger logger) {
  int errors = 0;
  List<Asset> assets = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    try {
      assets.add(
        Asset(
          assetClassId: row[0],
          assetName: row[1],
          acquireCost: row[2].isNotEmpty && row[2] != 'null'
              ? Decimal.parse(row[2])
              : null,
          quantityOnHand: row[3] == ''
              ? Decimal.parse('0')
              : Decimal.parse(row[3]),
          availableToPromise: row[4] == ''
              ? Decimal.parse('0')
              : Decimal.parse(row[4]),
          receivedDate: DateTime.tryParse(row[5]),
          expectedEndOfLifeDate: DateTime.tryParse(row[6]),
          product: Product(pseudoId: row[7]),
          location: Location(locationId: row[8]),
        ),
      );
    } catch (e) {
      String fieldList = '';
      assetCsvTitles.asMap().forEach(
        (index, value) => fieldList += "$value: ${row[index]}\n",
      );
      logger.e(
        "Error processing asset csv line: $fieldList \n"
        "error message: $e",
      );
      if (errors++ == 5) exit(1);
    }
  }
  return assets;
}

String csvFromAssets(List<Asset> assets) {
  var csv = [assetCsvFormat];
  for (Asset asset in assets) {
    csv.add(
      createCsvRow([
        asset.assetId,
        asset.assetClassId ?? '',
        asset.assetName ?? '',
        asset.acquireCost.toString(),
        asset.quantityOnHand.toString(),
        asset.availableToPromise.toString(),
        asset.receivedDate.toString(),
        asset.expectedEndOfLifeDate.toString(),
        asset.product!.pseudoId,
        asset.location!.locationId ?? '',
      ], assetCsvLength),
    );
  }
  return csv.join();
}
