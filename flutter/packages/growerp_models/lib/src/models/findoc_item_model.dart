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

import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logger/logger.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import '../create_csv_row.dart';
import '../json_converters.dart';
import 'models.dart';

part 'findoc_item_model.freezed.dart';
part 'findoc_item_model.g.dart';

@freezed
class FinDocItem with _$FinDocItem {
  FinDocItem._();
  factory FinDocItem({
    String? pseudoId, // for conversion only for related transaction
    FinDocType? docType, // for conversion only
    String? itemSeqId,
    ItemType? itemType,
    String? productId,
    String? pseudoProductId,
    String? description,
    Decimal? quantity,
    Decimal? price,
    GlAccount? glAccount,
    bool? isDebit,
    String? assetId,
    String? assetName,
    Location? location,
    @DateTimeConverter() DateTime? rentalFromDate,
    @DateTimeConverter() DateTime? rentalThruDate,
  }) = _FinDocItem;

  factory FinDocItem.fromJson(Map<String, dynamic> json) =>
      _$FinDocItemFromJson(json['finDocItem'] ?? json);
}

String finDocItemCsvFormat = "finDoc Id, finDocType, item Seq, "
    " productId, description, quantity, price/amount, accountCode, "
    " isDebit \r\n";
List<String> finDocItemCsvTitles = finDocItemCsvFormat.split(',');
int finDocItemCsvLength = finDocItemCsvTitles.length;

List<FinDocItem> CsvToFinDocItems(String csvFile, Logger logger) {
  int errors = 0;
  List<FinDocItem> finDocItems = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    try {
      finDocItems.add(FinDocItem(
        pseudoId: row[0],
        docType: FinDocType.tryParse(row[1]),
        itemSeqId: row[2],
        pseudoProductId: row[3],
        description: row[4],
        quantity: row[5] != 'null' && row[5].isNotEmpty
            ? Decimal.parse(row[5])
            : null,
        price: row[6] != 'null' && row[6].isNotEmpty
            ? Decimal.parse(row[6].replaceAll(',', ''))
            : null,
        glAccount: GlAccount(accountCode: row[7]),
        isDebit: row[8] == 'false' ? false : true,
      ));
    } catch (e) {
      String fieldList = '';
      finDocItemCsvTitles
          .asMap()
          .forEach((index, value) => fieldList += "$value: ${row[index]}\n");
      logger.e("Error processing findoc item csv line: $fieldList \n"
          "error message: $e");
      if (errors++ == 5) exit(1);
    }
  }
  return finDocItems;
}

String CsvFromFinDocItems(List<FinDocItem> finDocItems) {
  var csv = [finDocItemCsvFormat];
  for (FinDocItem finDocItem in finDocItems) {
    csv.add(createCsvRow([
      finDocItem.pseudoId ?? '',
      finDocItem.docType.toString(),
      finDocItem.itemSeqId.toString(),
      finDocItem.pseudoProductId ?? '',
      finDocItem.description ?? '',
      finDocItem.quantity?.toString() ?? '',
      finDocItem.price?.toString() ?? '',
      finDocItem.glAccount?.accountCode ?? '',
      finDocItem.isDebit?.toString() ?? '',
    ], finDocItemCsvLength));
  }
  return csv.join();
}
