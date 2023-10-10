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

import 'dart:convert';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

import '../create_csv_row.dart';
import 'models.dart';

part 'findoc_model.g.dart';

@JsonSerializable()
class FinDoc {
  @FinDocTypeConverter()
  FinDocType? docType; // order; invoice; payment etc
  bool sales;
  String? orderId;
  String? shipmentId;
  String? invoiceId;
  String? paymentId;
  String? transactionId;
  @PaymentInstrumentConverter()
  PaymentInstrument? paymentInstrument;
  @JsonKey(name: 'statusId')
  @FinDocStatusValConverter()
  FinDocStatusVal? status;
  @DateTimeConverter()
  DateTime? creationDate;
  @DateTimeConverter()
  DateTime? placedDate;
  String? description;
  User? otherUser; //a person responsible
  Company? otherCompany; // the other company
  Decimal? grandTotal;
  String? classificationId; // is productStore
  String? salesChannel;
  String? shipmentMethod;
  Address? address;
  String? telephoneNr;
  bool? isPosted;
  LedgerJournal? journal;
  List<FinDocItem> items;

  FinDoc({
    @FinDocTypeConverter() FinDocType? docType, // order, invoice, payment etc
    this.sales = true,
    this.orderId,
    this.shipmentId,
    this.invoiceId,
    this.paymentId,
    this.transactionId,
    this.paymentInstrument,
    this.status,
    this.creationDate,
    this.placedDate,
    this.description,
    this.otherUser, //a person responsible
    this.otherCompany, // the other company
    this.grandTotal,
    this.classificationId, // is productStore
    this.salesChannel,
    this.shipmentMethod,
    this.address,
    this.telephoneNr,
    this.isPosted,
    this.journal,
    this.items = const [],
  });

  factory FinDoc.fromJson(Map<String, dynamic> json) => _$FinDocFromJson(json);
  Map<String, dynamic> toJson() => _$FinDocToJson(this);

  //@override
  //String toString() => '$finDocName[$finDocId]';

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

  String? displayStatus(String classificationId) {
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

String FinDocCsvFormat() => "finDoc Id, FinDoc Name*, Description*, image\r\n";

List<String> FinDocCsvToJson(String csvFile) {
  List<String> finDocs = [];
  final result = fast_csv.parse(csvFile);
  FinDoc finDoc = FinDoc();
  List<FinDocItem> items = [];
  for (int index = 0; index < result.length; index++) {
    if (index == 0) continue;
    List<String> row = result[index];

    items.add(FinDocItem(
        itemSeqId: row[30],
        description: row[31],
        price: Decimal.parse(row[32])));

    finDoc = FinDoc(transactionId: row[0], description: row[1], items: items);
//    if (findoc)
    finDocs.add(jsonEncode(finDoc.toJson()));
  }

  return finDocs;
}

String CsvFromFinDocs(List<FinDoc> finDocs) {
//  final l = json.decode(result)['finDocs'] as Iterable;
//  List<FinDoc> finDocs = List<FinDoc>.from(
//      l.map((e) => FinDoc.fromJson(e as Map<String, dynamic>)));
  var csv = [];
  for (FinDoc finDoc in finDocs) {
    for (FinDocItem item in finDoc.items) {
      csv.add(createCsvRow([
        finDoc.id() ?? '',
        finDoc.description ?? '',
        item.itemSeqId.toString(),
        item.description ?? '',
        item.price.toString()
      ]));
    }
  }
  return csv.join();
}
