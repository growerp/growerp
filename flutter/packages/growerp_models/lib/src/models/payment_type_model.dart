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
