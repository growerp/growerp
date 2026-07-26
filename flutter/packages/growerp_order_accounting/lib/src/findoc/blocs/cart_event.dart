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
