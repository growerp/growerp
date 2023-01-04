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

part 'currency_model.freezed.dart';
part 'currency_model.g.dart';

@freezed
class Currency with _$Currency {
  Currency._();
  factory Currency({
    String? currencyId,
    String? description,
  }) = _Currency;
  factory Currency.fromJson(Map<String, dynamic> json) =>
      _$CurrencyFromJson(json);
}

List<Currency> currencies = [
  Currency(currencyId: 'EUR', description: 'European Euro'),
  Currency(currencyId: 'USD', description: 'United States Dollar'),
  Currency(currencyId: 'THB', description: 'Thailand Baht')
];
