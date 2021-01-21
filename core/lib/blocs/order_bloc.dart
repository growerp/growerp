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
import 'package:rxdart/rxdart.dart';

const _limit = 20;

mixin PurchOrderBloc on Bloc<OrderEvent, OrderState> {}
mixin SalesOrderBloc on Bloc<OrderEvent, OrderState> {}

class OrderBloc extends Bloc<OrderEvent, OrderState>
    with PurchOrderBloc, SalesOrderBloc {
  final repos;
  final bool sales;
  List<Order> orders = [];
  OrderBloc(this.repos, this.sales) : super(OrderInitial());

  @override
  Stream<Transition<OrderEvent, OrderState>> transformEvents(
    Stream<OrderEvent> events,
    TransitionFunction<OrderEvent, OrderState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  @override
  Stream<OrderState> mapEventToState(OrderEvent event) async* {
    final currentState = state;
    if (event is FetchOrder && !_hasReachedMax(currentState)) {
      if (currentState is OrderInitial) {
        dynamic result =
            await repos.getOrder(sales: sales, start: 0, limit: _limit);
        if (result is List<Order>) {
          yield OrderSuccess(
            orders: result,
            hasReachedMax: result.length < _limit ? true : false,
          );
        } else
          yield OrderProblem(result);
        return;
      }
      if (currentState is OrderSuccess) {
        dynamic result = await repos.getOrder(
            sales: sales,
            start: currentState.orders.length,
            limit: event.limit);
        if (result is List<Order>) {
          if (result.length < event.limit) {
            yield currentState.copyWith(
                orders: currentState.orders + result, hasReachedMax: true);
          } else {
            yield currentState.copyWith(
                orders: currentState.orders + result, hasReachedMax: false);
          }
        } else
          yield OrderProblem(result);
      }
    } else if (event is LoadOrder) {
      yield OrderLoading('Loading orders...');
      dynamic result = await repos.getOrder();
      if (result is List<Order>) {
        orders = result;
        yield OrderLoaded(orders);
      } else {
        yield OrderProblem(result);
      }
    } else if (event is CreateOrder) {
      yield OrderLoading('Create Order...');
      dynamic result = await repos.updateOrder(event.order);
      if (result is Order) {
        orders.add(result);
        yield OrderLoaded(orders, "Order created");
      } else
        yield OrderProblem(result);
    } else if (event is NextStatButtonPressed) {
      String newStatusId;
      switch (event.order.orderStatusId) {
        case 'OrderOpen':
          newStatusId = 'OrderPlaced';
          break;
        case 'OrderPlaced':
          newStatusId = 'OrderApproved';
          break;
        case 'OrderApproved':
          newStatusId = 'OrderCompleted';
          break;
      }
      yield OrderLoading('Next status: $newStatusId...');
      event.order.orderStatusId = newStatusId;
      dynamic result = await repos.updateOrder(event.order);
      if (result is Order) {
        int index = orders.indexWhere((x) => x.orderId == result.orderId);
        orders.replaceRange(index, index + 1, [event.order]);
        yield OrderLoaded(
            orders, "status update to ${event.order.orderStatusId}");
      } else
        yield OrderProblem(result);
    }
  }
}

bool _hasReachedMax(OrderState state) =>
    state is OrderSuccess && state.hasReachedMax;

// ===================events =====================
@immutable
abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object> get props => [];
}

class LoadOrder extends OrderEvent {}

class FetchOrder extends OrderEvent {
  final int limit;
  FetchOrder(this.limit);
  @override
  String toString() => "OrderFetched limit: $limit";
}

class CreateOrder extends OrderEvent {
  final Order order;
  CreateOrder(this.order);
  @override
  String toString() => 'Creating order $order';
}

class DeleteOrder extends OrderEvent {
  final int index;
  DeleteOrder(this.index);
  @override
  String toString() => "DeleteOrder: $index";
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

class NextStatButtonPressed extends OrderEvent {
  final Order order;
  NextStatButtonPressed(this.order);
  @override
  String toString() => 'Next status Pressed order ${order.orderStatusId}';
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
  const OrderLoaded(this.orders, [this.message]);
  @override
  String toString() => 'Orders loaded, ${orders?.length}';
}

class OrderProblem extends OrderState {
  final errorMessage;
  const OrderProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
}

class OrderSuccess extends OrderState {
  final List<Order> orders;
  final String message;
  final bool hasReachedMax;

  const OrderSuccess({
    this.orders,
    this.message,
    this.hasReachedMax,
  });

  OrderSuccess copyWith({
    List<Order> orders,
    String message,
    bool hasReachedMax,
  }) {
    return OrderSuccess(
      orders: orders ?? this.orders,
      message: message ?? this.message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [orders, hasReachedMax];

  @override
  String toString() => 'OrderSuccess { #orders: ${orders.length}, '
      'hasReachedMax: $hasReachedMax }';
}
