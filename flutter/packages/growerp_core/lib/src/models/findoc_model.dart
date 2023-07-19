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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../services/json_converters.dart';
import '../domains/domains.dart';

part 'findoc_model.freezed.dart';
part 'findoc_model.g.dart';

/// A generalized model for order, shipment, invoice, payment, transaction.
/// defined by the docType and sales (true/false)
@freezed
class FinDoc with _$FinDoc {
  FinDoc._();
  factory FinDoc({
    @FinDocTypeConverter() FinDocType? docType, // order, invoice, payment etc
    @Default(true) bool sales,
    String? orderId,
    String? shipmentId,
    String? invoiceId,
    String? paymentId,
    String? transactionId,
    @PaymentInstrumentConverter() PaymentInstrument? paymentInstrument,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'statusId')
    @FinDocStatusValConverter()
    FinDocStatusVal? status,
    @DateTimeConverter() DateTime? creationDate,
    @DateTimeConverter() DateTime? placedDate,
    String? description,
    User? otherUser, //a person responsible
    Company? otherCompany, // the other company
    Decimal? grandTotal,
    String? classificationId, // is productStore
    String? salesChannel,
    String? shipmentMethod,
    Address? address,
    String? telephoneNr,
    @Default([]) List<FinDocItem> items,
  }) = _FinDoc;

  factory FinDoc.fromJson(Map<String, dynamic> json) => _$FinDocFromJson(json);

  bool idIsNull() => (invoiceId == null &&
          orderId == null &&
          shipmentId == null &&
          invoiceId == null &&
          paymentId == null &&
          transactionId == null)
      ? true
      : false;

  String salesString() => sales == true ? 'Sales' : 'Purchase';

  String? id() => docType == FinDocType.transaction
      ? transactionId
      : docType == FinDocType.payment
          ? paymentId
          : docType == FinDocType.invoice
              ? invoiceId
              : docType == FinDocType.shipment
                  ? shipmentId
                  : docType == FinDocType.order
                      ? orderId
                      : null;

  String? chainId() =>
      shipmentId ?? (invoiceId ?? (paymentId ?? (orderId ?? (transactionId))));

  List<String?> otherIds() => docType == FinDocType.order
      ? ['shipment', shipmentId, 'invoice', invoiceId, 'payment', paymentId]
      : [];

  @override
  String toString() =>
      //    "rental: ${items[0].rentalFromDate?.toString().substring(0, 10)}/${items[0].rentalThruDate?.toString().substring(0, 10)} st:$status!"
      "$docType# $orderId!/$shipmentId/$invoiceId!/$paymentId! s/p: ${salesString()} "
      "Date: $creationDate! $description! items: ${items.length} "
      "asset: ${items.isNotEmpty ? items[0].assetName : ''} "
      "${items.isNotEmpty ? items[0].assetId : ''}"
      "descr: ${items.isNotEmpty ? items[0].description : ''} ";
//      "status: $status! otherUser: $otherUser! Items: ${items!.length}";

  String? displayName(String classificationId) {
    if (docType != FinDocType.order) {
      return finDocStatusValues[status.toString()];
    }
    switch (classificationId) {
      case 'AppHotel':
        return finDocStatusValuesHotel[status.toString()];
      default:
        return finDocStatusValues[status.toString()];
    }
  }
}

Map<String, String> finDocStatusValues = {
  // explanation of status values
  'FinDocPrep': 'in Preparation',
  'FinDocCreated': 'Created',
  'FinDocApproved': 'Approved',
  'FinDocCompleted': 'Completed',
  'FinDocCancelled': 'Cancelled'
};

Map<String, String> finDocStatusValuesHotel = {
  'FinDocPrep': 'in Preparation',
  'FinDocCreated': 'Created',
  'FinDocApproved': 'Checked In',
  'FinDocCompleted': 'Checked Out',
  'FinDocCancelled': 'Cancelled'
};
