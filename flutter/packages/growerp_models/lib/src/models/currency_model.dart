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

import '../rest_client.dart';

part 'currency_model.freezed.dart';
part 'currency_model.g.dart';

@freezed
abstract class Currency with _$Currency {
  Currency._();
  factory Currency({String? currencyId, String? description}) = _Currency;
  factory Currency.fromJson(Map<String, dynamic> json) =>
      _$CurrencyFromJson(json['currency'] ?? json);
}

/// Global currencies list, populated from the backend.
/// Starts with a fallback and gets replaced by [loadCurrencies].
List<Currency> currencies = [
  Currency(currencyId: 'USD', description: 'United States Dollar'),
  Currency(currencyId: 'EUR', description: 'Euro'),
  Currency(currencyId: 'GBP', description: 'British Pound'),
  Currency(currencyId: 'JPY', description: 'Japanese Yen'),
  Currency(currencyId: 'AUD', description: 'Australian Dollar'),
  Currency(currencyId: 'CAD', description: 'Canadian Dollar'),
  Currency(currencyId: 'CHF', description: 'Swiss Franc'),
  Currency(currencyId: 'CNY', description: 'Chinese Yuan Renminbi'),
  Currency(currencyId: 'INR', description: 'Indian Rupee'),
  Currency(currencyId: 'THB', description: 'Thailand Baht'),
];

bool _currenciesLoaded = false;

/// Load currencies from the backend via the UOM list service.
/// Replaces the global [currencies] list with all available currencies.
/// Safe to call multiple times — subsequent calls are no-ops.
Future<void> loadCurrencies(RestClient restClient) async {
  if (_currenciesLoaded) return;
  try {
    final uoms = await restClient.getUom(['UT_CURRENCY_MEASURE']);
    if (uoms.uoms.isNotEmpty) {
      currencies = uoms.uoms
          .map(
            (uom) =>
                Currency(currencyId: uom.uomId, description: uom.description),
          )
          .toList();
      _currenciesLoaded = true;
    }
  } catch (_) {
    // Keep the fallback list on failure
  }
}
