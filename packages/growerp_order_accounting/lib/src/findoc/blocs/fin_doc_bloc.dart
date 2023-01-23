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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:equatable/equatable.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../api_repository.dart';

part 'fin_doc_event.dart';
part 'fin_doc_state.dart';

const _finDocLimit = 20;

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
  FinDocBloc(this.repos, this.sales, this.docType)
      : super(const FinDocState()) {
    on<FinDocFetch>(_onFinDocFetch,
        transformer: finDocDroppable(const Duration(milliseconds: 100)));
    on<FinDocUpdate>(_onFinDocUpdate);
    on<FinDocShipmentReceive>(_onFinDocShipmentReceive);
    on<FinDocConfirmPayment>(_onFinDocConfirmPayment);
    on<FinDocGetUsers>(_onFinDocGetUsers);
    on<FinDocGetItemTypes>(_onFinDocGetItemTypes);
  }

  final FinDocAPIRepository repos;
  final bool sales;
  final FinDocType docType;

  String classificationId = GlobalConfiguration().get("classificationId");

  Future<void> _onFinDocFetch(
    FinDocFetch event,
    Emitter<FinDocState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    try {
      // start from record zero for initial and refresh
      if (state.status == FinDocStatus.initial || event.refresh) {
        if (state.status == FinDocStatus.initial &&
            docType == FinDocType.payment) add(FinDocGetItemTypes());

        ApiResult<List<FinDoc>> result = await repos.getFinDoc(
            sales: sales, docType: docType, searchString: event.searchString);
        return emit(result.when(
            success: (data) => state.copyWith(
                  status: FinDocStatus.success,
                  finDocs: data,
                  hasReachedMax: data.length < _finDocLimit ? true : false,
                  searchString: '',
                  message: event.refresh ? '${docType}s reloaded' : null,
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: FinDocStatus.failure, message: error.toString())));
      }
      // get first search page also for changed search
      else if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
          (state.searchString.isNotEmpty &&
              event.searchString != state.searchString)) {
        ApiResult<List<FinDoc>> compResult = await repos.getFinDoc(
            sales: sales, docType: docType, searchString: event.searchString);
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: FinDocStatus.success,
                  finDocs: data,
                  hasReachedMax: data.length < _finDocLimit ? true : false,
                  searchString: event.searchString,
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: FinDocStatus.failure, message: error.toString())));
      }
      // get next page also for search
      else {
        ApiResult<List<FinDoc>> compResult = await repos.getFinDoc(
            sales: sales, docType: docType, searchString: event.searchString);
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: FinDocStatus.success,
                  finDocs: List.of(state.finDocs)..addAll(data),
                  hasReachedMax: data.length < _finDocLimit ? true : false,
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: FinDocStatus.failure, message: error.toString())));
      }
    } catch (error) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onFinDocUpdate(
    FinDocUpdate event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      List<FinDoc> finDocs = List.from(state.finDocs);
      // need sort because were loaded at the top of the list:better seen by the user
      List<FinDocItem> items = List.from(event.finDoc.items);
      if (docType != FinDocType.shipment) {
        items.sort((a, b) => a.itemSeqId!.compareTo(b.itemSeqId!));
      }
      if (event.finDoc.idIsNull()) {
        // create
        ApiResult<FinDoc> compResult = await repos.createFinDoc(event.finDoc
            .copyWith(classificationId: classificationId, items: items));
        return emit(compResult.when(
            success: (data) {
              finDocs.insert(0, data);
              return state.copyWith(
                  status: FinDocStatus.success,
                  finDocs: finDocs,
                  message: '${event.finDoc.docType} ${finDocs[0].id()} added');
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: FinDocStatus.failure, message: error.toString())));
      } else {
        // update
        ApiResult<FinDoc> compResult = await repos.updateFinDoc(event.finDoc
            .copyWith(classificationId: classificationId, items: items));
        return emit(compResult.when(
            success: (data) {
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
                  index = finDocs.indexWhere((element) =>
                      element.shipmentId == event.finDoc.shipmentId);
                  break;
                case FinDocType.transaction:
                  index = finDocs.indexWhere((element) =>
                      element.transactionId == event.finDoc.transactionId);
                  break;
                default:
              }
              finDocs[index] = data;
              return state.copyWith(
                  status: FinDocStatus.success,
                  finDocs: finDocs,
                  message: "$docType ${event.finDoc.id()} updated");
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: FinDocStatus.failure, message: error.toString())));
      }
    } catch (error) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onFinDocShipmentReceive(
    FinDocShipmentReceive event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      ApiResult<FinDoc> shipResult = await repos.receiveShipment(event.finDoc);
      return emit(shipResult.when(
          success: (data) {
            List<FinDoc> finDocs = List.from(state.finDocs);
            int index = finDocs
                .indexWhere((element) => element.id() == event.finDoc.id());
            finDocs[index] = data;
            return state.copyWith(
                status: FinDocStatus.success, finDocs: finDocs);
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: FinDocStatus.failure, message: error.toString())));
    } catch (error) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onFinDocConfirmPayment(
    FinDocConfirmPayment event,
    Emitter<FinDocState> emit,
  ) async {
    emit(state.copyWith(status: FinDocStatus.loading));
    try {
      ApiResult<FinDoc> compResult = await repos.updateFinDoc(
          event.payment.copyWith(status: FinDocStatusVal.Completed));
      return emit(compResult.when(
          success: (data) {
            List<FinDoc> finDocs = List.from(state.finDocs);
            int index = finDocs.indexWhere(
                (element) => element.id() == event.payment.paymentId);
            finDocs[index] = data;
            return state.copyWith(
                status: FinDocStatus.success,
                finDocs: finDocs,
                message: 'Payment processed successfully');
          },
          failure: (error) => state.copyWith(
              status: FinDocStatus.failure, message: error.toString())));
    } catch (error) {
      return emit(state.copyWith(
          status: FinDocStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onFinDocGetUsers(
    FinDocGetUsers event,
    Emitter<FinDocState> emit,
  ) async {
    emit(state.copyWith(status: FinDocStatus.loading));
    try {
      ApiResult<List<User>> result = await repos.getUser(
          userGroups: event.userGroups, filter: event.filter);
      return emit(result.when(
          success: (data) => state.copyWith(
                users: data,
                status: FinDocStatus.success,
              ),
          failure: (error) => state.copyWith(
              status: FinDocStatus.failure, message: error.toString())));
    } catch (error) {
      return emit(state.copyWith(
          status: FinDocStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onFinDocGetItemTypes(
    FinDocGetItemTypes event,
    Emitter<FinDocState> emit,
  ) async {
    ApiResult<List<ItemType>> result = await repos.getItemTypes(sales: sales);
    return emit(result.when(
        success: (data) => state.copyWith(itemTypes: data),
        failure: (error) => state.copyWith(
            status: FinDocStatus.failure, message: error.toString())));
  }
}
