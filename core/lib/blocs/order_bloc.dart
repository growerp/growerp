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
import 'package:models/@models.dart';
import 'package:rxdart/rxdart.dart';

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
    if (event is FetchOrder) {
      if (currentState is OrderInitial) {
        dynamic result = await repos.getOrder(
            sales: sales, start: 0, limit: event.limit, search: event.search);
        if (result is List<Order>)
          yield OrderSuccess(
            orders: result,
            hasReachedMax: result.length < event.limit ? true : false,
          );
        else
          yield OrderProblem(result);
        return;
      }
      if (currentState is OrderSuccess) {
        if (event.search != null && currentState.search == null ||
            (currentState.search != null &&
                event.search != currentState.search)) {
          dynamic result = await repos.getOrder(
              sales: sales, start: 0, limit: event.limit, search: event.search);
          if (result is List<Order>)
            yield OrderSuccess(
                orders: result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          else
            yield OrderProblem(result);
        } else if (!_hasReachedMax(currentState)) {
          dynamic result = await repos.getOrder(
              sales: sales,
              start: currentState.orders.length,
              limit: event.limit,
              search: event.search);
          if (result is List<Order>)
            yield OrderSuccess(
                orders: currentState.orders + result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          else
            yield OrderProblem(result);
        }
      }
    } else if (currentState is OrderSuccess) {
      if (event is CreateOrder) {
        yield OrderLoading('Creating Order...');
        dynamic result = await repos.updateOrder(event.order);
        if (result is Order) {
          currentState.orders.add(result);
          yield currentState.copyWith(
              message: "order created id: ${result.orderId}");
        } else
          yield currentState.copyWith(errorMessage: result);
      } else if (event is UpdateOrder) {
        yield OrderLoading('Update order: ${event.order.orderId}');
        dynamic result = await repos.updateOrder(event.order);
        if (result is Order) {
          int index = currentState.orders
              .indexWhere((ord) => ord.orderId == result.orderId);
          currentState.orders.replaceRange(index, index + 1, [result]);
          yield currentState.copyWith(
              message: "status update to ${event.order.orderStatusId}");
        } else
          yield currentState.copyWith(errorMessage: result);
      }
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
  final String search;
  FetchOrder({this.limit, this.search});
  @override
  String toString() => "FetchOrder limit: $limit, search: $search";
}

class CreateOrder extends OrderEvent {
  final Order order;
  CreateOrder(this.order);
  @override
  String toString() => 'CreateOrder $order';
}

class UpdateOrder extends OrderEvent {
  final Order order;
  UpdateOrder(this.order);
  @override
  String toString() => 'UpdateOrder $order';
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
  const OrderLoading([this.message]);
  @override
  String toString() => 'Order loading, $message';
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
  final String errorMessage;
  final bool hasReachedMax;
  final String search;

  const OrderSuccess(
      {this.orders,
      this.message,
      this.errorMessage,
      this.hasReachedMax,
      this.search});

  OrderSuccess copyWith(
      {List<Order> orders,
      String message,
      String errorMessage,
      bool hasReachedMax,
      String search}) {
    return OrderSuccess(
        orders: orders ?? this.orders,
        message: message ?? this.message,
        errorMessage: errorMessage ?? this.errorMessage,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        search: search ?? this.search);
  }

  @override
  List<Object> get props => [orders, hasReachedMax, search];

  @override
  String toString() => 'OrderSuccess { #orders: ${orders.length}, '
      'hasReachedMax: $hasReachedMax }';
}
