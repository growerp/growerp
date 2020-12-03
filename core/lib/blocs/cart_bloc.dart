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
import 'package:models/models.dart';
import '../blocs/@blocs.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final OrderBloc orderBloc;
  final AuthBloc authBloc;
  final CatalogBloc catalogBloc;
  final CrmBloc crmBloc;
  StreamSubscription authBlocSubscription;
  StreamSubscription catalogBlocSubscription;
  StreamSubscription crmBlocSubscription;
  Order order = Order(grandTotal: Decimal.parse('0'), orderItems: []);
  Authenticate authenticate;
  Catalog catalog;
  List<User> crmUsers;

  CartBloc(this.authBloc, this.orderBloc, this.catalogBloc, this.crmBloc)
      : super(CartInitial()) {
    catalogBlocSubscription = catalogBloc.listen((state) {
      if (state is CatalogLoaded) {
        catalog = state.catalog;
      }
    });
    authBlocSubscription = authBloc.listen((state) {
      if (state is AuthAuthenticated) {
        authenticate = state.authenticate;
      }
      if (state is AuthUnauthenticated) {
        authenticate = state.authenticate;
      }
    });
    crmBlocSubscription = crmBloc.listen((state) {
      if (state is CrmLoaded) {
        crmUsers = state.crmUsers;
        add(CartCrmUpdated((crmBloc.state as CrmLoaded).crmUsers));
      }
    });
  }
  @override
  Future<void> close() {
    authBlocSubscription.cancel();
    catalogBlocSubscription.cancel();
    crmBlocSubscription.cancel();
    return super.close();
  }

  @override
  Stream<CartState> mapEventToState(CartEvent event) async* {
    if (event is LoadCart) {
      yield CartLoading();
      catalog = catalogBloc.catalog;
      crmUsers = crmBloc.crmUsers;
      order = event.order != null ? event.order : order;
      yield CartLoaded(authenticate, order, crmUsers, catalog?.products,
          "cart initial load.");
    } else if (event is UpdateCart) {
      yield CartLoading();
      order.customerPartyId = event.order.customerPartyId;
      event.order.orderItems[0].orderItemSeqId = order.orderItems.length + 1;
      event.order.orderItems[0].description = catalog.products
          .firstWhere((x) => event.order.orderItems[0].productId == x.productId)
          .description;
      order.orderItems.add(event.order.orderItems[0]);
      order.grandTotal = Decimal.parse('0');
      order.orderItems.forEach((x) {
        order.grandTotal += x.quantity * x.price;
      });
      yield CartLoaded(
          authenticate, order, crmUsers, catalog?.products, "cart updated");
    } else if (event is DeleteItemCart) {
      yield CartLoading();
      order.orderItems.removeAt(event.index);
      order.grandTotal = Decimal.parse('0');
      order.orderItems.forEach((x) {
        order.grandTotal += x.quantity * x.price;
      });
      yield CartLoaded(authenticate, order, crmUsers, catalog?.products,
          "Item# ${event.index} deleted");
    } else if (event is ConfirmCart) {
      yield CartLoading('Saving order...');
      try {
        orderBloc.add(CreateOrder(order));
        order = Order(grandTotal: Decimal.parse('0'), orderItems: []);
        yield CartLoaded(
            authenticate, order, crmUsers, catalog?.products, "order created");
      } catch (e) {
        yield CartProblem(e.toString());
      }
    } else if (event is CartCrmUpdated) {
      yield CartLoading();
      crmUsers = event.crmUsers;
      yield CartLoaded(
          authenticate, order, crmUsers, catalog?.products, "cart updated");
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
  String toString() => "Loading cart with order: $order";
}

class ConfirmCart extends CartEvent {}

class UpdateCart extends CartEvent {
  final Order order;
  const UpdateCart(this.order);
  @override
  String toString() => 'Updating cart: $order';
}

class DeleteItemCart extends CartEvent {
  final int index;
  DeleteItemCart(this.index);
  @override
  String toString() => 'Delete orderitem# $index';
}

class CatalogUpdated extends CartEvent {
  final Catalog catalog;
  CatalogUpdated(this.catalog);
  @override
  String toString() => 'Updating cart with catalog: $catalog';
}

class CartCrmUpdated extends CartEvent {
  final List<User> crmUsers;
  CartCrmUpdated(this.crmUsers);
  @override
  String toString() => 'Updating cart with crm users#: ${crmUsers?.length}';
}

class AuthUpdated extends CartEvent {
  final Authenticate authenticate;
  AuthUpdated(this.authenticate);
  @override
  String toString() => 'Updating cart with auth: $authenticate';
}

class PayOrder extends CartEvent {
  final Order order;
  PayOrder(this.order);
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
  final Authenticate authenticate;
  final Order order;
  final List customers;
  final List products;
  final String message;
  const CartLoaded(this.authenticate, this.order, this.customers, this.products,
      [this.message]);
  Decimal get totalPrice {
    if (order?.orderItems?.length == 0) return Decimal.parse('0');
    Decimal total = Decimal.parse('0');
    if (order != null)
      for (OrderItem i in order?.orderItems)
        total += (i.price * Decimal.parse(i.quantity.toString()));
    return total;
  }

  @override
  List<Object> get props => [order];
  @override
  String toString() =>
      'Cart loaded, cart items: ' +
      '${order?.orderItems?.length} value: $totalPrice '
          'Cust: ${customers?.length} Prod: ${products?.length}';
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
