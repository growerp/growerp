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

part of 'pos_cart_bloc.dart';

enum PosCartStatus { initial, loading, success, failure }

class PosCartLine extends Equatable {
  const PosCartLine(this.item, this.quantity);
  final PosCatalogItem item;
  final Decimal quantity;

  Decimal get total => (item.price ?? Decimal.zero) * quantity;

  @override
  List<Object?> get props => [item, quantity];
}

class PosCartState extends Equatable {
  const PosCartState({
    this.status = PosCartStatus.initial,
    this.lines = const <PosCartLine>[],
    this.taxTotal,
    this.grandTotal,
    this.message,
  });

  final PosCartStatus status;
  final List<PosCartLine> lines;
  final Decimal? taxTotal;
  final Decimal? grandTotal;
  final String? message;

  PosCartState copyWith({
    PosCartStatus? status,
    List<PosCartLine>? lines,
    Decimal? taxTotal,
    Decimal? grandTotal,
    String? message,
  }) {
    return PosCartState(
      status: status ?? this.status,
      lines: lines ?? this.lines,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, lines, taxTotal, grandTotal, message];

  @override
  String toString() =>
      '$status { #lines: ${lines.length}, total: $grandTotal }';
}
