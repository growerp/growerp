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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../json_converters.dart';

part 'tax_rate_model.freezed.dart';
part 'tax_rate_model.g.dart';

/// A sales tax rate. Without a category it is the default rate, with a
/// category it beats the default for the products in that category.
@freezed
abstract class TaxRate with _$TaxRate {
  TaxRate._();
  factory TaxRate({
    String? taxRateId,
    String? taxAuthorityId,
    String? taxName,
    Decimal? taxPercentage,
    String? productCategoryId,
    String? categoryName,
    bool? taxShipping,
    @DateTimeConverter() DateTime? fromDate,
    @DateTimeConverter() DateTime? thruDate,
  }) = _TaxRate;

  factory TaxRate.fromJson(Map<String, dynamic> json) =>
      _$TaxRateFromJson(json['taxRate'] ?? json);
}

/// The rates of the company and whether its POS prices include tax.
@freezed
abstract class TaxRates with _$TaxRates {
  TaxRates._();
  factory TaxRates({
    @Default([]) List<TaxRate> taxRates,
    @Default(false) bool pricesIncludeTax,
  }) = _TaxRates;

  factory TaxRates.fromJson(Map<String, dynamic> json) =>
      _$TaxRatesFromJson(json);
}
