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
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:models/models.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final repos;
  List<Order> orders;
  OrderBloc(this.repos) : super(OrderInitial());

  @override
  Stream<OrderState> mapEventToState(OrderEvent event) async* {
    if (event is LoadOrder) {
      yield OrderLoading('Loading orders...');
      dynamic result = await repos.getOrders();
      if (result is List<Order>) {
        orders = result;
        yield OrderLoaded(orders, 'orders loaded');
      } else {
        yield OrderProblem(result);
      }
    } else if (event is CreateOrder) {
      yield OrderLoading('Create Order...');
      dynamic result = await repos.createOrder(event.order);
      if (result is Order) {
        orders.add(result);
        yield OrderLoaded(orders, "order created");
      } else
        yield OrderProblem(result);
    }
  }
}

// ===================events =====================
@immutable
abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object> get props => [];
}

class LoadOrder extends OrderEvent {}

class CreateOrder extends OrderEvent {
  final Order order;
  CreateOrder(this.order);
  @override
  String toString() => 'Creating order $order';
}

class UpdateOrder extends OrderEvent {
  final List<Order> orders;
  final Order newOrder;
  UpdateOrder(this.orders, this.newOrder);
  @override
  String toString() => 'Updating order ${newOrder.orderId}';
}

class CancelOrder extends OrderEvent {
  final List<Order> orders;
  final String orderId;
  CancelOrder(this.orders, this.orderId);
  @override
  String toString() => 'Cancelling order $orderId';
}

// ================= state ========================
@immutable
abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {
  final String message;
  const OrderLoading(this.message);
  @override
  String toString() => 'Order loading, $message';
}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  final String message;
  const OrderLoaded(this.orders, this.message);
  @override
  String toString() => 'Orders loaded, ${orders?.length}';
}

class OrderProblem extends OrderState {
  final errorMessage;
  const OrderProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
}
