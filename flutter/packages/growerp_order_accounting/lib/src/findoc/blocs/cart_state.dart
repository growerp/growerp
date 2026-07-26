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

part of 'cart_bloc.dart';

enum CartStatus { initial, inProcess, saving, complete, failure }

class CartState extends Equatable {
  const CartState({
    this.status = CartStatus.initial,
    required this.finDoc,
    this.itemTypes = const [],
    this.message,
  });

  final CartStatus status;
  final String? message;
  final List<ItemType> itemTypes;
  final FinDoc finDoc;

  CartState copyWith({
    CartStatus? status,
    String? message,
    FinDoc? finDoc,
    List<ItemType>? itemTypes,
  }) {
    return CartState(
      status: status ?? this.status,
      finDoc: finDoc ?? this.finDoc,
      message: message,
      itemTypes: itemTypes ?? this.itemTypes,
    );
  }

  @override
  List<Object?> get props => [status, finDoc, message];

  @override
  String toString() =>
      '$status { ${finDoc.sales ? "Sales" : "Purchase"} '
      '${finDoc.docType} #items: ${finDoc.items.length}, '
      'message $message}';
}
