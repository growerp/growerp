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
import 'package:decimal/decimal.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:models/@models.dart';
import '../blocs/@blocs.dart';

mixin PurchCartBloc on Bloc<CartEvent, CartState> {}
mixin SalesCartBloc on Bloc<CartEvent, CartState> {}

class CartBloc extends Bloc<CartEvent, CartState>
    with PurchCartBloc, SalesCartBloc {
  final repos;
  final bool? sales;
  final FinDocBloc? finDocBloc;
  FinDoc? finDoc;
  CartBloc({this.repos, this.sales, this.finDocBloc}) : super(CartInitial());

  @override
  Stream<CartState> mapEventToState(CartEvent event) async* {
    if (event is LoadCart) {
      yield CartLoading();
      if (event.finDoc.orderId == null &&
          event.finDoc.invoiceId == null &&
          event.finDoc.paymentId == null)
        finDoc = await repos.getCart(sales: event.finDoc.sales);
      if (finDoc == null) finDoc = event.finDoc;
      yield CartLoaded(finDoc, "cart initial load.");
    } else if (event is AddToCart) {
      yield CartLoading();
      Decimal grandTotal = Decimal.parse('0');
      event.finDoc!.items!.forEach((x) {
        grandTotal += x.quantity! * x.price!;
        event.finDoc!.items!.add(event.newItem!
            .copyWith(itemSeqId: event.finDoc!.items!.length + 1));
      });
      finDoc = event.finDoc!.copyWith(grandTotal: grandTotal);
      await repos.saveCart(finDoc);
      yield CartLoaded(event.finDoc, "cart updated");
    } else if (event is DeleteFromCart) {
      yield CartLoading();
      if (event.index != null) {
        finDoc!.items!.removeAt(event.index!);
        Decimal grandTotal = Decimal.parse('0');
        int i = 0;
        finDoc!.items!.forEach((x) {
          finDoc!.items![i] = finDoc!.items![i].copyWith(itemSeqId: 1 + i++);
          grandTotal += x.quantity! * x.price!;
        });
        finDoc = finDoc!.copyWith(grandTotal: grandTotal);
      } else
        finDoc = FinDoc(sales: finDoc!.sales, items: []);
      await repos.saveCart(finDoc);
      yield CartLoaded(
          finDoc,
          event.index != null
              ? "Item# ${event.index} deleted"
              : "Cart cleared");
    } else if (event is CreateFinDocFromCart) {
      yield CartLoading('Saving ${finDoc!.docType}...');
      try {
        finDocBloc!.add(CreateFinDoc(finDoc));
        finDoc = FinDoc(
            sales: finDoc!.sales, grandTotal: Decimal.parse('0'), items: []);
        await repos.saveCart(finDoc);
        yield CartLoaded(finDoc, "${finDoc!.docType} created");
      } catch (e) {
        yield CartProblem(e.toString());
      }
    }
  }
}

// ===================events =====================
@immutable
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object> get props => [];
}

class LoadCart extends CartEvent {
  final FinDoc finDoc;
  LoadCart(this.finDoc);
  @override
  String toString() => "Loading cart with ${finDoc.docType}: $finDoc ...";
}

class CreateFinDocFromCart extends CartEvent {}

class AddToCart extends CartEvent {
  final FinDoc? finDoc;
  final FinDocItem? newItem;
  const AddToCart({this.finDoc, this.newItem});
  @override
  String toString() => 'Updating cart: $finDoc';
}

class DeleteFromCart extends CartEvent {
  final int? index;
  DeleteFromCart([this.index]);
  @override
  String toString() => 'Delete item# $index';
}

// ================= state ========================
@immutable
abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {
  final String? message;
  CartLoading([this.message]);
  String toString() => 'Cart loading...';
}

class CartLoaded extends CartState {
  final FinDoc? finDoc;
  final String? message;
  const CartLoaded(this.finDoc, [this.message]);
  Decimal get totalPrice {
    if (finDoc?.items?.length == 0) return Decimal.parse('0');
    Decimal total = Decimal.parse('0');
    if (finDoc != null && finDoc!.items != null)
      for (FinDocItem i in finDoc!.items!)
        total += (i.price! * Decimal.parse(i.quantity.toString()));
    return total;
  }

  @override
  List<Object?> get props => [finDoc];
  @override
  String toString() => 'Cart loaded with ${finDoc!.docType}: $finDoc';
}

class CartPaying extends CartState {}

class CartPaid extends CartState {
  final FinDoc? finDoc;
  const CartPaid({this.finDoc});
  List<Object?> get props => [finDoc];
  String toString() => 'Cart Paid, ${finDoc!.docType} : $finDoc';
}

class CartProblem extends CartState {
  final errorMessage;
  const CartProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
  String toString() => 'CartProblem: $errorMessage';
}
