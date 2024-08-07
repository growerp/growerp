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
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'item_type_model.freezed.dart';
part 'item_type_model.g.dart';

/// Item type used for order/invoice and payments
/// itemTypeId/direction is the unique key
@freezed
class ItemType with _$ItemType {
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
    itemTypes.add(ItemType(
      itemTypeId: row[0],
      accountCode: row[1],
      direction: row[2],
    ));
  }
  return itemTypes;
}
