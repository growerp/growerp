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

import 'dart:async';
import 'package:growerp_core/growerp_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

import '../findoc.dart';

part 'cart_event.dart';
part 'cart_state.dart';

mixin PurchaseCartBloc on Bloc<CartEvent, CartState> {}
mixin SalesCartBloc on Bloc<CartEvent, CartState> {}

class CartBloc extends Bloc<CartEvent, CartState>
    with PurchaseCartBloc, SalesCartBloc {
  CartBloc({
    required this.restClient,
    required this.sales,
    required this.docType,
    required this.finDocBloc,
  }) : super(
         CartState(
           finDoc: FinDoc(sales: sales, docType: docType, items: []),
           itemTypes: const <ItemType>[],
         ),
       ) {
    on<CartFetch>(_onCartFetch);
    on<CartCreateFinDoc>(_onCartCreateFinDoc);
    on<CartCancelFinDoc>(_onCartCancelFinDoc);
    on<CartHeader>(_onCartHeader);
    on<CartAdd>(_onCartAdd);
    on<CartDeleteItem>(_onCartDeleteItem);
    on<CartClear>(_onCartClear);
  }

  final RestClient restClient;
  final bool sales;
  final FinDocType docType;
  final FinDocBloc finDocBloc;

  Future<void> _onCartFetch(CartFetch event, Emitter<CartState> emit) async {
    if (state.status == CartStatus.initial) {
      FinDoc? resultFinDoc;
      if (event.finDoc.idIsNull()) {
        // get saved cart
        resultFinDoc = await PersistFunctions.getFinDoc(
          event.finDoc.sales,
          event.finDoc.docType!,
        );
      }
      // get item types
      ItemTypes result = await restClient.getItemTypes(sales: sales);
      return emit(
        state.copyWith(
          status: CartStatus.inProcess,
          itemTypes: result.itemTypes,
          finDoc: resultFinDoc ?? event.finDoc,
        ),
      );
    }
  }

  // store findoc in database
  Future<void> _onCartCreateFinDoc(
    CartCreateFinDoc event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.saving));
    finDocBloc.add(FinDocUpdate(event.finDoc));
    add(CartClear());
    return emit(
      state.copyWith(
        status: CartStatus.complete,
        finDoc: FinDoc(docType: docType, sales: sales, items: []),
      ),
    );
  }

  // cancel findoc in database
  Future<void> _onCartCancelFinDoc(
    CartCancelFinDoc event,
    Emitter<CartState> emit,
  ) async {
    finDocBloc.add(
      FinDocUpdate(event.finDoc.copyWith(status: FinDocStatusVal.cancelled)),
    );
    add(CartClear());
    return emit(
      state.copyWith(
        status: CartStatus.complete,
        finDoc: FinDoc(docType: docType, sales: sales),
      ),
    );
  }

  Future<void> _onCartHeader(CartHeader event, Emitter<CartState> emit) async {
    // save cart
    await PersistFunctions.persistFinDoc(event.finDoc);
    return emit(
      state.copyWith(status: CartStatus.inProcess, finDoc: event.finDoc),
    );
  }

  Future<void> _onCartAdd(CartAdd event, Emitter<CartState> emit) async {
    List<FinDocItem> items = List.from(state.finDoc.items);
    items.insert(
      0,
      event.newItem.copyWith(itemSeqId: (items.length + 1).toString()),
    );
    Decimal grandTotal = Decimal.parse('0');
    for (var x in items) {
      grandTotal += x.price! * (x.quantity ?? Decimal.parse('1'));
    }
    var finDoc = event.finDoc.copyWith(
      otherUser: event.finDoc.otherUser,
      description: event.finDoc.description,
      items: items,
      grandTotal: grandTotal,
    );
    // save cart
    await PersistFunctions.persistFinDoc(finDoc);
    return emit(state.copyWith(status: CartStatus.inProcess, finDoc: finDoc));
  }

  Future<void> _onCartDeleteItem(
    CartDeleteItem event,
    Emitter<CartState> emit,
  ) async {
    List<FinDocItem> items = List.from(state.finDoc.items);
    items.removeAt(event.index);
    Decimal grandTotal = Decimal.parse('0');
    int i = 0;
    for (var item in items) {
      items[i] = items[i].copyWith(itemSeqId: (1 + i++).toString());
      grandTotal += item.quantity ?? Decimal.parse('1') * item.price!;
    }
    var finDoc = state.finDoc.copyWith(grandTotal: grandTotal, items: items);
    // save cart
    await PersistFunctions.persistFinDoc(finDoc);
    emit(state.copyWith(status: CartStatus.inProcess, finDoc: finDoc));
  }

  Future<void> _onCartClear(CartClear event, Emitter<CartState> emit) async {
    var finDoc = FinDoc(sales: sales, docType: docType, items: []);
    // clear cart
    await PersistFunctions.removeFinDoc(finDoc);
    return emit(state.copyWith(status: CartStatus.inProcess, finDoc: finDoc));
  }
}
