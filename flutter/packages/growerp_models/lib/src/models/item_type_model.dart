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
/// same class used for paymentTypes
@freezed
class ItemType with _$ItemType {
  ItemType._();
  factory ItemType({
    @Default('') String itemTypeId,
    @Default('') String itemTypeName,
    @Default('') String accountCode,
    @Default('') String accountName,
    String? direction, //item type I:incoming,O:outgoing,E:either
    String? isPayable, //payment type payable=Y/receivable=N
    String? isApplied, //payment type Y:applied, N: unapplied, E: either
  }) = _ItemType;

  factory ItemType.fromJson(Map<String, dynamic> json) =>
      _$ItemTypeFromJson(json);
}

String itemTypeCsvFormat = "itemTypeId, accountCode, direction(I/O/E), "
    "isPayable(Y/N/E), isApplied(Y/N/E) \r\n";
int itemTypeCsvLength = itemTypeCsvFormat.split(',').length;

// import
List<ItemType> CsvToItemTypes(String csvFile) {
  List<ItemType> ItemTypes = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    ItemTypes.add(ItemType(
      itemTypeId: row[0],
      accountCode: row[1],
      direction: row[2],
      isPayable: row[3],
      isApplied: row[4],
    ));
  }
  return ItemTypes;
}
