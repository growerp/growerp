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
  int limit = 20;
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

  Stream<FinDocState> getFinDoc(
      {required dynamic event,
      List<FinDoc> finDocs = const <FinDoc>[],
      int start = 0,
      String? searchString}) async* {
    dynamic result = await repos.getFinDoc(
      id: event.id,
      open: true,
      sales: sales,
      docType: docType,
      start: start,
      limit: event.limit,
      search: searchString,
      customerCompanyPartyId: event.customerCompanyPartyId,
    );
    if (result is List<FinDoc>)
      yield FinDocSuccess(
        finDocs: finDocs + result,
        searchString: searchString,
        hasReachedMax: result.length < (event.limit ?? limit) ? true : false,
      );
    else
      yield FinDocProblem(result);
  }

  @override
  Stream<FinDocState> mapEventToState(FinDocEvent event) async* {
    final FinDocState currentState = state;
    if (event is FetchFinDoc) {
      // refresh or initial
      if (event.refresh || currentState is FinDocInitial) {
        yield* getFinDoc(
            event: event,
            searchString: currentState is FinDocSuccess
                ? currentState.searchString
                : null);
      } else if (currentState is FinDocSuccess) {
        // if we need to search
        if (event.search != null && currentState.searchString == null ||
            (currentState.searchString != null &&
                event.search != currentState.searchString)) {
          yield* getFinDoc(
              event: event,
              finDocs: currentState.finDocs,
              searchString: event.search);
        } else if (!_hasReachedMax(currentState)) {
          // get next page
          yield* getFinDoc(
              event: event,
              finDocs: currentState.finDocs,
              start: currentState.finDocs.length);
        }
      }
    } else if (currentState is FinDocSuccess) {
      if (event is CreateFinDoc) {
        yield FinDocLoading('Creating ${event.finDoc.docType}...');
        dynamic result = await repos.updateFinDoc(event.finDoc);
        if (result is List<FinDoc> && result.isNotEmpty) {
          currentState.finDocs.add(result[0]);
          yield currentState.copyWith(
              message: "${result[0].docType} #${result[0].id()} created");
        } else
          yield FinDocProblem(result);
      } else if (event is UpdateFinDoc) {
        yield FinDocLoading('Update ${event.finDoc.docType}');
        dynamic result = await repos.updateFinDoc(event.finDoc);
        if (result is List<FinDoc> && result.isNotEmpty) {
          late int index;
          switch (result[0].docType) {
            case 'order':
              index = currentState.finDocs
                  .indexWhere((ord) => ord.orderId == result[0].orderId);
              break;
            case 'invoice':
              index = currentState.finDocs
                  .indexWhere((ord) => ord.invoiceId == result[0].invoiceId);
              break;
            case 'payment':
              index = currentState.finDocs
                  .indexWhere((ord) => ord.paymentId == result[0].paymentId);
              break;
          }
          currentState.finDocs[index] = result[0];
          yield currentState.copyWith(message: "${result[0].docType} updated");
        } else
          yield FinDocProblem(result);
      } else if (event is DeleteFinDoc) {
        yield FinDocLoading('Deleting ${event.finDoc.docType}');
        dynamic result = await repos
            .updateFinDoc(event.finDoc.copyWith(statusId: "FinDocCancelled"));
        if (result is List<FinDoc>) {
          yield currentState.copyWith(
              message: "${event.finDoc.docType} status to Cancelled");
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
  final bool refresh;
  final String? id;
  final String? docType; // to get a single document id, docType
  final int? limit;
  final String? search;
  final String? customerCompanyPartyId;
  FetchFinDoc(
      {this.refresh = false,
      this.limit,
      this.search,
      this.id,
      this.docType,
      this.customerCompanyPartyId});
  @override
  String toString() =>
      "FetchFinDoc refresh: $refresh limit: $limit, search: $search";
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

class DeleteFinDoc extends FinDocEvent {
  final FinDoc finDoc;
  DeleteFinDoc(this.finDoc);
  @override
  String toString() => 'UpdateFinDoc $finDoc';
}

// ================= state ========================
@immutable
abstract class FinDocState extends Equatable {
  const FinDocState();
  @override
  List<Object?> get props => [];
}

class FinDocInitial extends FinDocState {}

class FinDocLoading extends FinDocState {
  final String? message;
  const FinDocLoading([this.message]);
  @override
  String toString() => 'FinDoc loading, $message';
}

class FinDocProblem extends FinDocState {
  final errorMessage;
  const FinDocProblem(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class FinDocSuccess extends FinDocState {
  final List<FinDoc> finDocs;
  final String? message;
  final bool hasReachedMax;
  final String? searchString;

  const FinDocSuccess(
      {required this.finDocs,
      required this.hasReachedMax,
      this.message,
      this.searchString});

  FinDocSuccess copyWith(
      {List<FinDoc>? finDocs,
      String? message,
      String? errorMessage,
      bool? hasReachedMax,
      String? searchString}) {
    return FinDocSuccess(
        finDocs: finDocs ?? this.finDocs,
        message: message ?? this.message,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        searchString: searchString ?? this.searchString);
  }

  @override
  List<Object?> get props => [finDocs, hasReachedMax, searchString];

  @override
  String toString() => 'FinDocSuccess { finDocs#: ${finDocs.length}, '
      'hasReachedMax: $hasReachedMax }';
}
