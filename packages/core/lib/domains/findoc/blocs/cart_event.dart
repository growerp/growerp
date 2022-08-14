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

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object> get props => [];
}

class CartFetch extends CartEvent {
  const CartFetch(this.finDoc);
  final FinDoc finDoc;
}

class CartCreateFinDoc extends CartEvent {
  const CartCreateFinDoc(this.finDoc);
  final FinDoc finDoc;
}

class CartCancelFinDoc extends CartEvent {
  const CartCancelFinDoc(this.finDoc);
  final FinDoc finDoc;
}

class CartHeader extends CartEvent {
  const CartHeader(this.finDoc);
  final FinDoc finDoc;
}

class CartAdd extends CartEvent {
  const CartAdd({required this.finDoc, required this.newItem});
  final FinDoc finDoc;
  final FinDocItem newItem;
}

class CartDeleteItem extends CartEvent {
  const CartDeleteItem(this.index);
  final int index;
}

class CartClear extends CartEvent {}
