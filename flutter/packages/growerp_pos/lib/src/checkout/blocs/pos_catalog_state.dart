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

part of 'pos_catalog_bloc.dart';

enum PosCatalogStatus { initial, loading, success, scanned, failure }

class PosCatalogState extends Equatable {
  const PosCatalogState({
    this.status = PosCatalogStatus.initial,
    this.items = const <PosCatalogItem>[],
    this.modifierGroups = const <PosModifierGroup>[],
    this.pricesIncludeTax = false,
    this.currencyId,
    this.scanned,
    this.message,
  });

  final PosCatalogStatus status;
  final List<PosCatalogItem> items;
  final List<PosModifierGroup> modifierGroups;
  final bool pricesIncludeTax;
  final String? currencyId;

  /// the product of the last barcode, with status scanned
  final PosCatalogItem? scanned;
  final String? message;

  PosCatalogState copyWith({
    PosCatalogStatus? status,
    List<PosCatalogItem>? items,
    List<PosModifierGroup>? modifierGroups,
    bool? pricesIncludeTax,
    String? currencyId,
    PosCatalogItem? scanned,
    String? message,
  }) {
    return PosCatalogState(
      status: status ?? this.status,
      items: items ?? this.items,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      pricesIncludeTax: pricesIncludeTax ?? this.pricesIncludeTax,
      currencyId: currencyId ?? this.currencyId,
      scanned: scanned,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    modifierGroups,
    pricesIncludeTax,
    currencyId,
    scanned,
    message,
  ];

  @override
  String toString() => '$status { #items: ${items.length}, message: $message }';
}
