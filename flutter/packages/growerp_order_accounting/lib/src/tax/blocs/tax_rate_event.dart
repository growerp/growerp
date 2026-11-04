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

part of 'tax_rate_bloc.dart';

abstract class TaxRateEvent extends Equatable {
  const TaxRateEvent();
  @override
  List<Object?> get props => [];
}

class TaxRateFetch extends TaxRateEvent {
  const TaxRateFetch();
}

/// create when the rate has no id yet
class TaxRateUpdate extends TaxRateEvent {
  const TaxRateUpdate(this.taxRate);
  final TaxRate taxRate;
  @override
  List<Object?> get props => [taxRate];
}

class TaxRateDelete extends TaxRateEvent {
  const TaxRateDelete(this.taxRate);
  final TaxRate taxRate;
  @override
  List<Object?> get props => [taxRate];
}

class TaxSettingsUpdate extends TaxRateEvent {
  const TaxSettingsUpdate({required this.pricesIncludeTax});
  final bool pricesIncludeTax;
  @override
  List<Object?> get props => [pricesIncludeTax];
}
