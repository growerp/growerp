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

abstract class PosCartEvent extends Equatable {
  const PosCartEvent();
  @override
  List<Object?> get props => [];
}

class PosCartAdd extends PosCartEvent {
  const PosCartAdd(this.item);
  final PosCatalogItem item;
  @override
  List<Object?> get props => [item];
}

/// zero removes the line
class PosCartQuantity extends PosCartEvent {
  const PosCartQuantity(this.productId, this.quantity);
  final String productId;
  final Decimal quantity;
  @override
  List<Object?> get props => [productId, quantity];
}

class PosCartClear extends PosCartEvent {
  const PosCartClear();
}
