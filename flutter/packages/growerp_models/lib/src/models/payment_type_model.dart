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

part 'payment_type_model.freezed.dart';
part 'payment_type_model.g.dart';

/// Payment type used for payments
/// key is type/isPayable/isApplied
@freezed
abstract class PaymentType with _$PaymentType {
  PaymentType._();
  factory PaymentType({
    @Default('') String paymentTypeId,
    @Default(false) bool isPayable,
    @Default(false) bool isApplied,
    @Default('') String paymentTypeName,
    @Default('') String accountCode,
    @Default('') String accountName,
  }) = _PaymentType;

  factory PaymentType.fromJson(Map<String, dynamic> json) =>
      _$PaymentTypeFromJson(json['paymentType'] ?? json);
}

String paymentTypeCsvFormat =
    "paymentTypeId, accountCode, "
    "isPayable(Y/N), isApplied(Y/N), \r\n";
int paymentTypeCsvLength = paymentTypeCsvFormat.split(',').length;

// import
List<PaymentType> csvToPaymentTypes(String csvFile) {
  List<PaymentType> paymentTypes = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    paymentTypes.add(
      PaymentType(
        paymentTypeId: row[0],
        accountCode: row[1],
        isPayable: row[2] == "true" ? true : false,
        isApplied: row[3] == "true" ? true : false,
      ),
    );
  }
  return paymentTypes;
}
