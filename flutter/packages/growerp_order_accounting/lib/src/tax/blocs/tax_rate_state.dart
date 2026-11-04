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

enum TaxRateStatus { initial, loading, success, failure }

class TaxRateState extends Equatable {
  const TaxRateState({
    this.status = TaxRateStatus.initial,
    this.taxRates = const <TaxRate>[],
    this.pricesIncludeTax = false,
    this.message,
  });

  final TaxRateStatus status;
  final List<TaxRate> taxRates;
  final bool pricesIncludeTax;
  final String? message;

  TaxRateState copyWith({
    TaxRateStatus? status,
    List<TaxRate>? taxRates,
    bool? pricesIncludeTax,
    String? message,
  }) {
    return TaxRateState(
      status: status ?? this.status,
      taxRates: taxRates ?? this.taxRates,
      pricesIncludeTax: pricesIncludeTax ?? this.pricesIncludeTax,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, message, taxRates, pricesIncludeTax];

  @override
  String toString() =>
      '$status { #rates: ${taxRates.length}, message: $message }';
}
