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
  final bool sales;
  final OrderBloc orderBloc;
  Order order;
  CartBloc({this.repos, this.sales, this.orderBloc}) : super(CartInitial());

  @override
  Stream<CartState> mapEventToState(CartEvent event) async* {
    if (event is LoadCart) {
      yield CartLoading();
      print("===cartbloc load order: ${event.order}");
      if (event.order.orderId == null)
        order = await repos.getCart(sales: event.order.sales);
      print("===cartbloc pref order: $order");
      if (order == null) order = event.order;
      print("===cartbloc returned order: $order");
      yield CartLoaded(order, "cart initial load.");
    } else if (event is AddToCart) {
      yield CartLoading();
      event.newItem.orderItemSeqId = event.order.orderItems.length + 1;
      event.order.orderItems.add(event.newItem);
      event.order.grandTotal = Decimal.parse('0');
      event.order.orderItems.forEach((x) {
        event.order.grandTotal += x.quantity * x.price;
      });
      order = event.order;
      await repos.saveCart(event.order);
      yield CartLoaded(event.order, "cart updated");
    } else if (event is DeleteFromCart) {
      yield CartLoading();
      if (event.index != null) {
        order.orderItems.removeAt(event.index);
        order.grandTotal = Decimal.parse('0');
        int i = 0;
        order.orderItems.forEach((x) {
          order.orderItems[i].orderItemSeqId = 1 + i++;
          order.grandTotal += x.quantity * x.price;
        });
      } else
        order = Order(sales: order.sales, orderItems: []);
      await repos.saveCart(order);
      yield CartLoaded(
          order,
          event.index != null
              ? "Item# ${event.index} deleted"
              : "Cart cleared");
    } else if (event is CreateOrderFromCart) {
      yield CartLoading('Saving order...');
      print("saving order $order");
      try {
        orderBloc.add(CreateOrder(order));
        order = Order(grandTotal: Decimal.parse('0'), orderItems: []);
        await repos.saveCart(order);
        yield CartLoaded(order, "order created");
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
  final Order order;
  LoadCart(this.order);
  @override
  String toString() => "Loading cart with order: $order ...";
}

class CreateOrderFromCart extends CartEvent {}

class AddToCart extends CartEvent {
  final Order order;
  final OrderItem newItem;
  const AddToCart({this.order, this.newItem});
  @override
  String toString() => 'Updating cart: $order';
}

class DeleteFromCart extends CartEvent {
  final int index;
  DeleteFromCart([this.index]);
  @override
  String toString() => 'Delete orderitem# $index';
}

// ================= state ========================
@immutable
abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {
  final String message;
  CartLoading([this.message]);
  String toString() => 'Cart loading...';
}

class CartLoaded extends CartState {
  final Order order;
  final String message;
  const CartLoaded(this.order, [this.message]);
  Decimal get totalPrice {
    if (order?.orderItems?.length == 0) return Decimal.parse('0');
    Decimal total = Decimal.parse('0');
    if (order != null && order.orderItems != null)
      for (OrderItem i in order?.orderItems)
        total += (i.price * Decimal.parse(i.quantity.toString()));
    return total;
  }

  @override
  List<Object> get props => [order];
  @override
  String toString() => 'Cart loaded with order: $order';
}

class CartPaying extends CartState {}

class CartPaid extends CartState {
  final String orderId;
  const CartPaid({this.orderId});
  List<Object> get props => [orderId];
  String toString() => 'Cart Paid, orderId : $orderId';
}

class CartProblem extends CartState {
  final errorMessage;
  const CartProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
}
