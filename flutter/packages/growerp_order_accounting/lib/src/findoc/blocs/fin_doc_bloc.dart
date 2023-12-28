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
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

part 'fin_doc_event.dart';
part 'fin_doc_state.dart';

mixin PurchaseInvoiceBloc on Bloc<FinDocEvent, FinDocState> {}
mixin SalesInvoiceBloc on Bloc<FinDocEvent, FinDocState> {}
mixin PurchasePaymentBloc on Bloc<FinDocEvent, FinDocState> {}
mixin SalesPaymentBloc on Bloc<FinDocEvent, FinDocState> {}
mixin PurchaseOrderBloc on Bloc<FinDocEvent, FinDocState> {}
mixin SalesOrderBloc on Bloc<FinDocEvent, FinDocState> {}
mixin OutgoingShipmentBloc on Bloc<FinDocEvent, FinDocState> {}
mixin IncomingShipmentBloc on Bloc<FinDocEvent, FinDocState> {}
mixin TransactionBloc on Bloc<FinDocEvent, FinDocState> {}

EventTransformer<E> finDocDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

EventTransformer<E> finDocItemDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class FinDocBloc extends Bloc<FinDocEvent, FinDocState>
    with
        PurchaseInvoiceBloc,
        SalesInvoiceBloc,
        PurchasePaymentBloc,
        SalesPaymentBloc,
        PurchaseOrderBloc,
        SalesOrderBloc,
        IncomingShipmentBloc,
        OutgoingShipmentBloc,
        TransactionBloc {
  FinDocBloc(this.restClient, this.sales, this.docType, this.classificationId,
      {this.journalId = ''})
      : super(const FinDocState()) {
    on<FinDocFetch>(_onFinDocFetch,
        transformer: finDocDroppable(const Duration(milliseconds: 100)));
    on<FinDocUpdate>(_onFinDocUpdate);
    on<FinDocShipmentReceive>(_onFinDocShipmentReceive);
    on<FinDocGetItemTypes>(_onFinDocGetItemTypes);
    on<FinDocGetPaymentTypes>(_onFinDocGetPaymentTypes);
  }

  final RestClient restClient;
  final String classificationId;
  final bool sales;
  final FinDocType docType;
  final String journalId;
  int start = 0;

  Future<void> _onFinDocFetch(
    FinDocFetch event,
    Emitter<FinDocState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') {
      return;
    }
    List<FinDoc> current = [];
    if (state.status == FinDocStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
      current = [];
    } else {
      start = state.finDocs.length;
      current = List.of(state.finDocs);
    }
    // start from record zero for initial and refresh
    try {
      if (docType == FinDocType.payment) {
        add(FinDocGetPaymentTypes(sales));
      } else {
        add(FinDocGetItemTypes());
      }
      FinDocs result = await restClient.getFinDoc(
        start: start,
        limit: event.limit,
        sales: sales,
        docType: docType,
        searchString: event.searchString,
        journalId: event.journalId,
      );

      emit(state.copyWith(
          status: FinDocStatus.success,
          finDocs: current..addAll(result.finDocs),
          hasReachedMax: result.finDocs.length < event.limit,
          searchString: event.searchString,
          message: event.refresh ? '${docType}s reloaded' : null));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure,
          finDocs: state.finDocs,
          message: getDioError(e)));
    }
  }

  Future<void> _onFinDocUpdate(
    FinDocUpdate event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      emit(state.copyWith(status: FinDocStatus.loading));
      List<FinDoc> finDocs = List.from(state.finDocs);
      // need sort because were loaded at the top of the list:better seen by the user
      List<FinDocItem> items = List.from(event.finDoc.items);
      if (docType != FinDocType.shipment && docType != FinDocType.payment) {
        items.sort((a, b) => a.itemSeqId!.compareTo(b.itemSeqId!));
      }
      if (event.finDoc.idIsNull()) {
        // create
        FinDoc compResult = await restClient.createFinDoc(
            finDoc: event.finDoc
                .copyWith(classificationId: classificationId, items: items));
        finDocs.insert(0, compResult);
        return emit(state.copyWith(
            status: FinDocStatus.success,
            finDocs: finDocs,
            message: '${event.finDoc.docType} ${finDocs[0].id()} added'));
      } else {
        // update
        FinDoc compResult = await restClient.updateFinDoc(
            finDoc: event.finDoc
                .copyWith(classificationId: classificationId, items: items));
        late int index;
        switch (docType) {
          case FinDocType.order:
            index = finDocs.indexWhere(
                (element) => element.orderId == event.finDoc.orderId);
            break;
          case FinDocType.payment:
            index = finDocs.indexWhere(
                (element) => element.paymentId == event.finDoc.paymentId);
            break;
          case FinDocType.invoice:
            index = finDocs.indexWhere(
                (element) => element.invoiceId == event.finDoc.invoiceId);
            break;
          case FinDocType.shipment:
            index = finDocs.indexWhere(
                (element) => element.shipmentId == event.finDoc.shipmentId);
            break;
          case FinDocType.transaction:
            index = finDocs.indexWhere((element) =>
                element.transactionId == event.finDoc.transactionId);
            break;
          default:
        }
        finDocs[index] = compResult;
        return emit(state.copyWith(
            status: FinDocStatus.success,
            finDocs: finDocs,
            message: "$docType ${event.finDoc.id()} updated"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, finDocs: [], message: getDioError(e)));
    }
  }

  Future<void> _onFinDocShipmentReceive(
    FinDocShipmentReceive event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      emit(state.copyWith(status: FinDocStatus.loading));
      FinDoc compResult =
          await restClient.receiveShipment(finDoc: event.finDoc);
      List<FinDoc> finDocs = List.from(state.finDocs);
      int index =
          finDocs.indexWhere((element) => element.id() == event.finDoc.id());
      finDocs[index] = compResult;
      return emit(
          state.copyWith(status: FinDocStatus.success, finDocs: finDocs));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, finDocs: [], message: getDioError(e)));
    }
  }

  Future<void> _onFinDocGetItemTypes(
    FinDocGetItemTypes event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      ItemTypes compResult = await restClient.getItemTypes(sales: sales);
      return emit(state.copyWith(itemTypes: compResult.itemTypes));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, finDocs: [], message: getDioError(e)));
    }
  }

  Future<void> _onFinDocGetPaymentTypes(
    FinDocGetPaymentTypes event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      ItemTypes result = await restClient.getPaymentTypes(sales: sales);
      return emit(state.copyWith(itemTypes: result.itemTypes));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, finDocs: [], message: getDioError(e)));
    }
  }
}
