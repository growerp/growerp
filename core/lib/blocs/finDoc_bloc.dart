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

mixin PurchInvoiceBloc on Bloc<FinDocEvent, FinDocState> {}
mixin SalesInvoiceBloc on Bloc<FinDocEvent, FinDocState> {}
mixin PurchPaymentBloc on Bloc<FinDocEvent, FinDocState> {}
mixin SalesPaymentBloc on Bloc<FinDocEvent, FinDocState> {}
mixin PurchaseOrderBloc on Bloc<FinDocEvent, FinDocState> {}
mixin SalesOrderBloc on Bloc<FinDocEvent, FinDocState> {}
mixin TransactionBloc on Bloc<FinDocEvent, FinDocState> {}

class FinDocBloc extends Bloc<FinDocEvent, FinDocState>
    with
        PurchInvoiceBloc,
        SalesInvoiceBloc,
        PurchPaymentBloc,
        SalesPaymentBloc,
        PurchaseOrderBloc,
        SalesOrderBloc,
        TransactionBloc {
  final repos;
  final bool sales;
  final String docType; // invoice,payment,order
  List<FinDoc> finDocs = [];
  FinDocBloc(this.repos, this.sales, this.docType) : super(FinDocInitial());

  @override
  Stream<Transition<FinDocEvent, FinDocState>> transformEvents(
    Stream<FinDocEvent> events,
    TransitionFunction<FinDocEvent, FinDocState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  @override
  Stream<FinDocState> mapEventToState(FinDocEvent event) async* {
    final currentState = state;
    if (event is FetchFinDoc) {
      if (currentState is FinDocInitial) {
        yield FinDocLoading("Getting documents...");
        dynamic result = await repos.getFinDoc(
            sales: sales,
            docType: docType,
            start: 0,
            limit: event.limit,
            search: event.search);
        if (result is List<FinDoc>)
          yield FinDocSuccess(
            finDocs: result,
            hasReachedMax: result.length < event.limit ? true : false,
          );
        else
          yield FinDocProblem(result);
        return;
      }
      if (currentState is FinDocSuccess) {
        if (event.search != null && currentState.search == null ||
            (currentState.search != null &&
                event.search != currentState.search)) {
          dynamic result = await repos.getFinDoc(
              sales: sales,
              docType: docType,
              start: 0,
              limit: event.limit,
              search: event.search);
          if (result is List<FinDoc>)
            yield FinDocSuccess(
                finDocs: result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          else
            yield FinDocProblem(result);
        } else if (!_hasReachedMax(currentState)) {
          dynamic result = await repos.getFinDoc(
              sales: sales,
              docType: docType,
              start: currentState.finDocs.length,
              limit: event.limit,
              search: event.search);
          if (result is List<FinDoc>)
            yield FinDocSuccess(
                finDocs: currentState.finDocs + result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          else
            yield FinDocProblem(result);
        }
      }
    } else if (currentState is FinDocSuccess) {
      if (event is CreateFinDoc) {
        yield FinDocLoading('Creating ${event.finDoc.docType}...');
        dynamic result = await repos.updateFinDoc(event.finDoc);
        if (result is FinDoc) {
          currentState.finDocs.add(result);
          yield currentState.copyWith(
              message: "${result.docType} updated/created");
        } else
          yield FinDocProblem(result);
      } else if (event is UpdateFinDoc) {
        yield FinDocLoading('Update ${event.finDoc.docType}');
        dynamic result = await repos.updateFinDoc(event.finDoc);
        if (result is FinDoc) {
          int index;
          switch (result.docType) {
            case 'order':
              index = currentState.finDocs
                  .indexWhere((ord) => ord.orderId == result.orderId);
              break;
            case 'invoice':
              index = currentState.finDocs
                  .indexWhere((ord) => ord.invoiceId == result.invoiceId);
              break;
            case 'payment':
              index = currentState.finDocs
                  .indexWhere((ord) => ord.paymentId == result.paymentId);
              break;
          }
          currentState.finDocs.replaceRange(index, index + 1, [result]);
          yield currentState.copyWith(
              message: "status updated to ${result.statusId}");
        } else
          yield FinDocProblem(result);
      }
    }
  }
}

bool _hasReachedMax(FinDocState state) =>
    state is FinDocSuccess && state.hasReachedMax;

// ===================events =====================
@immutable
abstract class FinDocEvent extends Equatable {
  const FinDocEvent();
  @override
  List<Object> get props => [];
}

class LoadFinDoc extends FinDocEvent {}

class FetchFinDoc extends FinDocEvent {
  final int limit;
  final String search;
  FetchFinDoc({this.limit, this.search});
  @override
  String toString() => "FetchFinDoc limit: $limit, search: $search";
}

class CreateFinDoc extends FinDocEvent {
  final FinDoc finDoc;
  CreateFinDoc(this.finDoc);
  @override
  String toString() => 'CreateFinDoc $finDoc';
}

class UpdateFinDoc extends FinDocEvent {
  final FinDoc finDoc;
  UpdateFinDoc(this.finDoc);
  @override
  String toString() => 'UpdateFinDoc $finDoc';
}

// ================= state ========================
@immutable
abstract class FinDocState extends Equatable {
  const FinDocState();
  @override
  List<Object> get props => [];
}

class FinDocInitial extends FinDocState {}

class FinDocLoading extends FinDocState {
  final String message;
  const FinDocLoading([this.message]);
  @override
  String toString() => 'FinDoc loading, $message';
}

class FinDocProblem extends FinDocState {
  final errorMessage;
  const FinDocProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
}

class FinDocSuccess extends FinDocState {
  final List<FinDoc> finDocs;
  final String message;
  final String errorMessage;
  final bool hasReachedMax;
  final String search;

  const FinDocSuccess(
      {this.finDocs,
      this.message,
      this.errorMessage,
      this.hasReachedMax,
      this.search});

  FinDocSuccess copyWith(
      {List<FinDoc> finDocs,
      String message,
      String errorMessage,
      bool hasReachedMax,
      String search}) {
    return FinDocSuccess(
        finDocs: finDocs ?? this.finDocs,
        message: message ?? this.message,
        errorMessage: errorMessage ?? this.errorMessage,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        search: search ?? this.search);
  }

  @override
  List<Object> get props => [finDocs, hasReachedMax, search];

  @override
  String toString() => 'FinDocSuccess { finDocs#: ${finDocs.length}, '
      'hasReachedMax: $hasReachedMax }';
}
