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
mixin RequestBloc on Bloc<FinDocEvent, FinDocState> {}

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

List<ItemType> saveItemTypes = [];
List<PaymentType> savePaymentTypes = [];

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
        TransactionBloc,
        RequestBloc {
  FinDocBloc(this.restClient, this.sales, this.docType, this.classificationId,
      {this.journalId = ''})
      : super(const FinDocState()) {
    on<FinDocFetch>(_onFinDocFetch,
        transformer: finDocDroppable(const Duration(milliseconds: 100)));
    on<FinDocUpdate>(_onFinDocUpdate);
    on<FinDocShipmentReceive>(_onFinDocShipmentReceive);
    on<FinDocGetItemTypes>(_onFinDocGetItemTypes);
    on<FinDocUpdateItemType>(_onFinDocUpdateItemType);
    on<FinDocGetPaymentTypes>(_onFinDocGetPaymentTypes);
    on<FinDocUpdatePaymentType>(_onFinDocUpdatePaymentType);
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
    emit(state.copyWith(status: FinDocStatus.loading));
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
      ItemTypes itemTypes = ItemTypes();
      PaymentTypes paymentTypes = PaymentTypes();
      if (docType == FinDocType.payment && state.paymentTypes.isEmpty) {
        paymentTypes = await restClient.getPaymentTypes(sales: sales);
      } else if (state.itemTypes.isEmpty) {
        itemTypes = await restClient.getItemTypes(sales: sales);
      }
      FinDocs result = await restClient.getFinDoc(
        finDocId: event.finDocId,
        start: start,
        limit: event.limit,
        sales: event.sales ?? sales,
        docType: event.docType ?? docType,
        searchString: event.searchString,
        journalId: event.journalId,
        my: event.my,
      );

      emit(state.copyWith(
          status: FinDocStatus.success,
          finDocs: current..addAll(result.finDocs),
          itemTypes: itemTypes.itemTypes,
          paymentTypes: paymentTypes.paymentTypes,
          hasReachedMax: result.finDocs.length < event.limit,
          searchString: event.searchString,
          message: event.refresh ? '${docType}s reloaded' : null));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure,
          finDocs: state.finDocs,
          message: await getDioError(e)));
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
            message: '${event.finDoc.docType} ${compResult.pseudoId} added'));
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
          case FinDocType.payment:
            index = finDocs.indexWhere(
                (element) => element.paymentId == event.finDoc.paymentId);
          case FinDocType.invoice:
            index = finDocs.indexWhere(
                (element) => element.invoiceId == event.finDoc.invoiceId);
          case FinDocType.shipment:
            index = finDocs.indexWhere(
                (element) => element.shipmentId == event.finDoc.shipmentId);
          case FinDocType.transaction:
            index = finDocs.indexWhere((element) =>
                element.transactionId == event.finDoc.transactionId);
          case FinDocType.request:
            index = finDocs.indexWhere(
                (element) => element.requestId == event.finDoc.requestId);
          default:
        }
        if (docType == FinDocType.transaction &&
            event.finDoc.status == FinDocStatusVal.cancelled) {
          finDocs.removeAt(index);
        } else {
          finDocs[index] = compResult;
        }
        return emit(state.copyWith(
            status: FinDocStatus.success,
            finDocs: finDocs,
            message: "$docType ${compResult.pseudoId!} "
                "${docType == FinDocType.transaction && event.finDoc.status == FinDocStatusVal.cancelled ? 'Deleted' : 'updated'}"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: await getDioError(e)));
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
          status: FinDocStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onFinDocGetItemTypes(
    FinDocGetItemTypes event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      late List<ItemType> itemTypes;
      if (event.searchString == null) {
        ItemTypes compResult =
            await restClient.getItemTypes(sales: event.sales);
        saveItemTypes = List.from(compResult.itemTypes);
        itemTypes = List.from(saveItemTypes);
      } else {
        itemTypes = List.from(saveItemTypes
            .where((element) =>
                '${element.itemTypeName.toLowerCase()} '
                        '${element.direction.toLowerCase()}'
                    .contains(event.searchString!.toLowerCase()) ||
                element.accountCode
                    .toLowerCase()
                    .contains(event.searchString!.toLowerCase()))
            .toList());
      }
      return emit(
          state.copyWith(itemTypes: itemTypes, status: FinDocStatus.success));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onFinDocUpdateItemType(
    FinDocUpdateItemType event,
    Emitter<FinDocState> emit,
  ) async {
    emit(state.copyWith(status: FinDocStatus.loading));
    try {
      List<ItemType> itemTypes = List.from(state.itemTypes);
      ItemType compResult = await restClient.updateItemType(
          itemType: event.itemType, update: event.update, delete: event.delete);
      int index = itemTypes.indexWhere((element) =>
          element.itemTypeId == event.itemType.itemTypeId &&
          element.direction == event.itemType.direction);
      int saveIndex = saveItemTypes.indexWhere((element) =>
          element.itemTypeId == event.itemType.itemTypeId &&
          element.direction == event.itemType.direction);
      if (event.update == true) {
        itemTypes[index] = itemTypes[index].copyWith(
            accountName: compResult.accountName,
            accountCode: compResult.accountCode);
        saveItemTypes[saveIndex] = saveItemTypes[saveIndex].copyWith(
            accountName: compResult.accountName,
            accountCode: compResult.accountCode);
      }
      if (event.delete == true) {
        itemTypes[index] =
            itemTypes[index].copyWith(accountCode: '', accountName: '');
        saveItemTypes[saveIndex] =
            saveItemTypes[saveIndex].copyWith(accountCode: '', accountName: '');
      }
      return emit(state.copyWith(
          itemTypes: itemTypes,
          status: FinDocStatus.success,
          message: "Item Type: ${event.itemType.itemTypeName} "
              "${event.update != null ? 'updated' : 'removed'}"));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onFinDocGetPaymentTypes(
    FinDocGetPaymentTypes event,
    Emitter<FinDocState> emit,
  ) async {
    try {
      late List<PaymentType> paymentTypes;
      if (event.searchString == null) {
        PaymentTypes compResult =
            await restClient.getPaymentTypes(sales: event.sales);
        savePaymentTypes = List.from(compResult.paymentTypes);
        paymentTypes = List.from(savePaymentTypes);
      } else {
        paymentTypes = List.from(savePaymentTypes
            .where((element) =>
                "${element.paymentTypeName.toLowerCase()} -- "
                        "${element.isPayable ? 'outgoing' : 'incoming'} -- "
                        "${element.isApplied ? 'y' : 'n'}"
                    .contains(event.searchString!.toLowerCase()) ||
                element.accountCode
                    .toLowerCase()
                    .contains(event.searchString!.toLowerCase()))
            .toList());
      }
      return emit(state.copyWith(
          paymentTypes: paymentTypes, status: FinDocStatus.success));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onFinDocUpdatePaymentType(
    FinDocUpdatePaymentType event,
    Emitter<FinDocState> emit,
  ) async {
    emit(state.copyWith(status: FinDocStatus.loading));
    try {
      List<PaymentType> paymentTypes = List.from(state.paymentTypes);
      PaymentType compResult = await restClient.updatePaymentType(
          paymentType: event.paymentType,
          update: event.update,
          delete: event.delete);
      int index = paymentTypes.indexWhere((element) =>
          element.paymentTypeId == event.paymentType.paymentTypeId &&
          element.isPayable == event.paymentType.isPayable &&
          element.isApplied == event.paymentType.isApplied);
      int saveIndex = savePaymentTypes.indexWhere((element) =>
          element.paymentTypeId == event.paymentType.paymentTypeId &&
          element.isPayable == event.paymentType.isPayable &&
          element.isApplied == event.paymentType.isApplied);
      if (event.update == true) {
        paymentTypes[index] = paymentTypes[index].copyWith(
            accountName: compResult.accountName,
            accountCode: compResult.accountCode);
        savePaymentTypes[saveIndex] = savePaymentTypes[saveIndex].copyWith(
            accountName: compResult.accountName,
            accountCode: compResult.accountCode);
      }
      if (event.delete == true) {
        paymentTypes[index] =
            paymentTypes[index].copyWith(accountCode: '', accountName: '');
        savePaymentTypes[saveIndex] = savePaymentTypes[saveIndex]
            .copyWith(accountCode: '', accountName: '');
      }
      return emit(state.copyWith(
          paymentTypes: paymentTypes,
          status: FinDocStatus.success,
          message: "Payment Type: ${event.paymentType.paymentTypeName} "
              "${event.update != null ? 'updated' : 'removed'}"));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: FinDocStatus.failure, message: await getDioError(e)));
    }
  }
}
