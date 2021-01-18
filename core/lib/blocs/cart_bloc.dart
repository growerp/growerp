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
  final CategoryBloc categoryBloc;
  final ProductBloc productBloc;
  final UserBloc customerBloc;
  final UserBloc supplierBloc;
  StreamSubscription authBlocSubscription;
  StreamSubscription categoryBlocSubscription;
  StreamSubscription productBlocSubscription;
  StreamSubscription customerBlocSubscription;
  StreamSubscription supplierBlocSubscription;
  Order order;
  Authenticate authenticate;
  List<ProductCategory> categories;
  List<Product> products;
  List<User> customers;
  List<User> suppliers;

  CartBloc(this.authBloc, this.orderBloc, this.productBloc, this.categoryBloc,
      this.customerBloc, this.supplierBloc)
      : super(CartInitial()) {
    categoryBlocSubscription = categoryBloc.listen((state) {
      if (state is CategorySuccess) {
        categories = state.categories;
      }
    });
    productBlocSubscription = productBloc.listen((state) {
      if (state is ProductSuccess) {
        products = state.products;
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
    customerBlocSubscription = customerBloc.listen((state) {
      if (state is UserFetchSuccess) {
        customers = state.users;
        add(CartUserUpdated((customerBloc.state as UserFetchSuccess).users));
      }
    });
    supplierBlocSubscription = customerBloc.listen((state) {
      if (state is UserFetchSuccess) {
        suppliers = state.users;
        add(CartUserUpdated((supplierBloc.state as UserFetchSuccess).users));
      }
    });
  }
  @override
  Future<void> close() {
    authBlocSubscription.cancel();
    categoryBlocSubscription.cancel();
    productBlocSubscription.cancel();
    customerBlocSubscription.cancel();
    supplierBlocSubscription.cancel();
    return super.close();
  }

  @override
  Stream<CartState> mapEventToState(CartEvent event) async* {
    if (event is LoadCart) {
      yield CartLoading();
      authenticate = authBloc.authenticate;
      categories = categoryBloc.categories;
      products = productBloc.products;
      customers = customerBloc.users;
      suppliers = supplierBloc.users;
      order = event.order != null ? event.order : order;
      yield CartLoaded(authenticate, order, customers, suppliers, categories,
          products, "cart initial load.");
    } else if (event is UpdateCart) {
      yield CartLoading();
      order = event.order;
      event.order.orderItems[0].orderItemSeqId =
          order.orderItems == null ? 1 : order.orderItems.length + 1;
      event.order.orderItems[0].description = products
          .firstWhere((x) => event.order.orderItems[0].productId == x.productId)
          .productName;
      if (order.orderItems == null) order.orderItems = [];
      order.orderItems.add(event.order.orderItems[0]);
      order.grandTotal = Decimal.parse('0');
      order.orderItems.forEach((x) {
        order.grandTotal += x.quantity * x.price;
      });
      yield CartLoaded(authenticate, order, customers, suppliers, categories,
          products, "cart updated");
    } else if (event is DeleteItemCart) {
      yield CartLoading();
      order.orderItems.removeAt(event.index);
      order.grandTotal = Decimal.parse('0');
      order.orderItems.forEach((x) {
        order.grandTotal += x.quantity * x.price;
      });
      yield CartLoaded(authenticate, order, customers, suppliers, categories,
          products, "Item# ${event.index} deleted");
    } else if (event is ConfirmCart) {
      yield CartLoading('Saving order...');
      print("saving order $order");
      try {
        orderBloc.add(CreateOrder(order));
        order = Order(grandTotal: Decimal.parse('0'), orderItems: []);
        yield CartLoaded(authenticate, order, customers, suppliers, categories,
            products, "order created");
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

class CategoryCartUpdated extends CartEvent {
  final ProductCategory category;
  CategoryCartUpdated(this.category);
  @override
  String toString() => 'Updating cart with Category: $category';
}

class CartUserUpdated extends CartEvent {
  final List<User> users;
  CartUserUpdated(this.users);
  @override
  String toString() => 'Updating cart with user users#: '
      '${users?.length}/${users?.length}';
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
  final List<User> customers;
  final List<User> suppliers;
  final List<ProductCategory> categories;
  final List<Product> products;
  final String message;
  const CartLoaded(this.authenticate, this.order, this.customers,
      this.suppliers, this.categories, this.products,
      [this.message]);
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
  String toString() => 'Cart loaded, '
      'company: ${authenticate?.company?.partyId}'
      'cart items '
      '${order?.orderItems?.length} value: $totalPrice '
      'Cust: ${customers?.length} Suppliers: ${suppliers?.length} '
      'Prod: ${products?.length}';
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
