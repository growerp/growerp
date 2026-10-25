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
import 'package:growerp_models/src/json_converters.dart';

part 'exchange_rate_model.freezed.dart';
part 'exchange_rate_model.g.dart';

/// Central, read-only currency exchange rate, refreshed weekly by the backend.
@freezed
abstract class ExchangeRate with _$ExchangeRate {
  ExchangeRate._();
  factory ExchangeRate({
    @Default('') String fromCurrencyId,
    @Default('') String toCurrencyId,
    Decimal? rate,
    @DateTimeConverter() DateTime? fromDate,
  }) = _ExchangeRate;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateFromJson(json['exchangeRate'] ?? json);
}
