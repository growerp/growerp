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

part of 'bom_bloc.dart';

enum BomStatus { initial, loading, success, failure }

class BomState extends Equatable {
  const BomState({
    this.status = BomStatus.initial,
    this.boms = const <Bom>[],
    this.bomItems = const <BomItem>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.productId,
  });

  final BomStatus status;
  final String? message;
  final List<Bom> boms;
  final List<BomItem> bomItems;
  final bool hasReachedMax;
  final String searchString;
  final String? productId;

  BomState copyWith({
    BomStatus? status,
    String? message,
    List<Bom>? boms,
    List<BomItem>? bomItems,
    bool? hasReachedMax,
    String? searchString,
    String? productId,
  }) {
    return BomState(
      status: status ?? this.status,
      boms: boms ?? this.boms,
      bomItems: bomItems ?? this.bomItems,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      productId: productId ?? this.productId,
    );
  }

  @override
  List<Object?> get props => [boms, bomItems, hasReachedMax, status, productId];

  @override
  String toString() =>
      '$status { #boms: ${boms.length}, #bomItems: ${bomItems.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
