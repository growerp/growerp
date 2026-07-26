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
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'item_type_model.freezed.dart';
part 'item_type_model.g.dart';

/// Item type used for order/invoice and payments
/// itemTypeId/direction is the unique key
@freezed
abstract class ItemType with _$ItemType {
  ItemType._();
  factory ItemType({
    @Default('') String itemTypeId,
    @Default('') String direction, //item type I:incoming,O:outgoing
    @Default('') String itemTypeName,
    @Default('') String accountCode,
    @Default('') String accountName,
  }) = _ItemType;

  factory ItemType.fromJson(Map<String, dynamic> json) =>
      _$ItemTypeFromJson(json['itemType'] ?? json);
}

String itemTypeCsvFormat = "itemTypeId, accountCode, direction(I/O/E), \r\n";
int itemTypeCsvLength = itemTypeCsvFormat.split(',').length;

// import
List<ItemType> csvToItemTypes(String csvFile) {
  List<ItemType> itemTypes = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    itemTypes.add(
      ItemType(itemTypeId: row[0], accountCode: row[1], direction: row[2]),
    );
  }
  return itemTypes;
}
