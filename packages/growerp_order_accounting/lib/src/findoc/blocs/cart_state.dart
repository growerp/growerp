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
  String toString() => '$status { ${finDoc.sales ? "Sales" : "Purchase"} '
      '${finDoc.docType} #items: ${finDoc.items.length}, '
      'message $message}';
}
