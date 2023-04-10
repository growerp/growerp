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

import 'dart:async';
import 'package:growerp_core/growerp_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../findoc.dart';

part 'cart_event.dart';
part 'cart_state.dart';

mixin PurchaseCartBloc on Bloc<CartEvent, CartState> {}
mixin SalesCartBloc on Bloc<CartEvent, CartState> {}

class CartBloc extends Bloc<CartEvent, CartState>
    with PurchaseCartBloc, SalesCartBloc {
  CartBloc(
      {required this.repos,
      required this.sales,
      required this.docType,
      required this.finDocBloc})
      : super(CartState(
            finDoc: FinDoc(sales: sales, docType: docType, items: []),
            itemTypes: const <ItemType>[])) {
    on<CartFetch>(_onCartFetch);
    on<CartCreateFinDoc>(_onCartCreateFinDoc);
    on<CartCancelFinDoc>(_onCartCancelFinDoc);
    on<CartHeader>(_onCartHeader);
    on<CartAdd>(_onCartAdd);
    on<CartDeleteItem>(_onCartDeleteItem);
    on<CartClear>(_onCartClear);
  }

  final APIRepository repos;
  final bool sales;
  final FinDocType docType;
  final FinDocBloc finDocBloc;

  Future<void> _onCartFetch(
    CartFetch event,
    Emitter<CartState> emit,
  ) async {
    try {
      if (state.status == CartStatus.initial) {
        FinDoc? resultFinDoc;
        if (event.finDoc.idIsNull()) {
          // get saved cart
          resultFinDoc = await PersistFunctions.getFinDoc(
              event.finDoc.sales, event.finDoc.docType!);
        }
        // get item types
        ApiResult<List<ItemType>> result =
            await repos.getItemTypes(sales: sales);
        return emit(result.when(
            success: (data) => state.copyWith(
                status: CartStatus.inProcess,
                itemTypes: data,
                finDoc: resultFinDoc ?? event.finDoc),
            failure: (NetworkExceptions error) => state.copyWith(
                status: CartStatus.failure, message: error.toString())));
      }
    } catch (error) {
      emit(state.copyWith(
          status: CartStatus.failure, message: error.toString()));
    }
  }

  // store findoc in database
  Future<void> _onCartCreateFinDoc(
    CartCreateFinDoc event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CartStatus.saving));
      finDocBloc.add(FinDocUpdate(event.finDoc));
      add(CartClear());
      return emit(
        state.copyWith(
          status: CartStatus.complete,
          finDoc: FinDoc(docType: docType, sales: sales, items: []),
        ),
      );
    } catch (error) {
      emit(state.copyWith(
          status: CartStatus.failure, message: error.toString()));
    }
  }

  // cancel findoc in database
  Future<void> _onCartCancelFinDoc(
    CartCancelFinDoc event,
    Emitter<CartState> emit,
  ) async {
    try {
      finDocBloc.add(FinDocUpdate(
          event.finDoc.copyWith(status: FinDocStatusVal.cancelled)));
      add(CartClear());
      return emit(
        state.copyWith(
          status: CartStatus.complete,
          finDoc: FinDoc(docType: docType, sales: sales),
        ),
      );
    } catch (error) {
      emit(state.copyWith(
          status: CartStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onCartHeader(
    CartHeader event,
    Emitter<CartState> emit,
  ) async {
    try {
      // save cart
      await PersistFunctions.persistFinDoc(event.finDoc);
      return emit(
        state.copyWith(
          status: CartStatus.inProcess,
          finDoc: event.finDoc,
        ),
      );
    } catch (error) {
      emit(state.copyWith(
          status: CartStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onCartAdd(
    CartAdd event,
    Emitter<CartState> emit,
  ) async {
    try {
      List<FinDocItem> items = List.from(state.finDoc.items);
      items.insert(
          0, event.newItem.copyWith(itemSeqId: (items.length + 1).toString()));
      Decimal grandTotal = Decimal.parse('0');
      for (var x in items) {
        grandTotal += x.quantity! * x.price!;
      }
      var finDoc = event.finDoc.copyWith(
          otherUser: event.finDoc.otherUser,
          description: event.finDoc.description,
          items: items,
          grandTotal: grandTotal);
      // save cart
      await PersistFunctions.persistFinDoc(finDoc);
      return emit(
        state.copyWith(
          status: CartStatus.inProcess,
          finDoc: finDoc,
        ),
      );
    } catch (error) {
      emit(state.copyWith(
          status: CartStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onCartDeleteItem(
    CartDeleteItem event,
    Emitter<CartState> emit,
  ) async {
    try {
      List<FinDocItem> items = List.from(state.finDoc.items);
      items.removeAt(event.index);
      Decimal grandTotal = Decimal.parse('0');
      int i = 0;
      for (var x in items) {
        items[i] = items[i].copyWith(itemSeqId: (1 + i++).toString());
        grandTotal += x.quantity! * x.price!;
      }
      var finDoc = state.finDoc.copyWith(grandTotal: grandTotal, items: items);
      // save cart
      await PersistFunctions.persistFinDoc(finDoc);
      emit(
        state.copyWith(
          status: CartStatus.inProcess,
          finDoc: finDoc,
        ),
      );
    } catch (error) {
      emit(state.copyWith(
          status: CartStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onCartClear(
    CartClear event,
    Emitter<CartState> emit,
  ) async {
    try {
      var finDoc = FinDoc(sales: sales, docType: docType, items: []);
      // clear cart
      await PersistFunctions.removeFinDoc(finDoc);
      return emit(
        state.copyWith(
          status: CartStatus.inProcess,
          finDoc: finDoc,
        ),
      );
    } catch (error) {
      emit(state.copyWith(
          status: CartStatus.failure, message: error.toString()));
    }
  }
}
