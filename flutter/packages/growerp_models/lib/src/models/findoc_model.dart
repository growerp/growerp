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

import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:logger/logger.dart';
import '../create_csv_row.dart';
import '../json_converters.dart';
import 'models.dart';

part 'findoc_model.freezed.dart';
part 'findoc_model.g.dart';

/// A generalized model for order, shipment, invoice, payment, transaction.
/// defined by the docType and sales (true/false)
@freezed
class FinDoc with _$FinDoc {
  FinDoc._();
  factory FinDoc({
    FinDocType? docType, // order, invoice, payment, shipment, transaction
    @Default(true) bool sales,
    String? pseudoId,
    String? orderId,
    String? shipmentId,
    String? invoiceId,
    String? paymentId,
    String? transactionId,
    String? pseudoOrderId,
    String? pseudoShipmentId,
    String? pseudoInvoiceId,
    String? pseudoPaymentId,
    String? pseudoTransactionId,
    String?
        reference, //transaction id field saved in AcctgTrans/theirAcctgTransId in backend
    @PaymentInstrumentConverter() PaymentInstrument? paymentInstrument,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'statusId')
    @FinDocStatusValConverter()
    FinDocStatusVal? status,
    @DateTimeConverter() DateTime? creationDate,
    @DateTimeConverter() DateTime? placedDate,
    String? description,
    User? otherUser, //a contact person
    Company? otherCompany, // the other company
    Decimal? grandTotal,
    String? classificationId, // is productStore
    String? salesChannel,
    String? shipmentMethod,
    Address? address,
    String? telephoneNr,
    bool? isPosted,
    LedgerJournal? journal,
    PaymentMethod? paymentMethod, // check , credit card, electronic
    @Default([]) List<FinDocItem> items,
  }) = _FinDoc;

  factory FinDoc.fromJson(Map<String, dynamic> json) =>
      _$FinDocFromJson(json['finDoc'] ?? json);

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
      "$docType# $pseudoId/$orderId!/$shipmentId/$invoiceId!/$paymentId! s/p: ${salesString()} "
      "Date: $creationDate! $description! items: ${items.length} "
      "asset: ${items.isNotEmpty ? items[0].assetName : ''} "
      "${items.isNotEmpty ? items[0].assetId : ''}"
      "descr: ${items.isNotEmpty ? items[0].description : ''} ";
//      "status: $status! otherUser: $otherUser! Items: ${items!.length}";

  String? displayStatus(String classificationId) {
    if (status == null) return '??';
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

String finDocCsvFormat = "Id, Sales, finDocType, descr, date, "
    "other user Id, other company Id, other company Name, reference number, "
    "check number(blank is cash), totalAmount, Invoice/Payment, \r\n";
List<String> finDocCsvTitles = finDocCsvFormat.split(',');
int finDocCsvLength = finDocItemCsvTitles.length;

// import
List<FinDoc> CsvToFinDocs(String csvFile, Logger logger) {
  int errors = 0;
  List<FinDoc> finDocs = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first || row[0].isEmpty) continue;
    try {
      finDocs.add(
        FinDoc(
          pseudoId: row[0],
          sales: row[1] == 'false' ? false : true,
          docType: FinDocType.tryParse(row[2]),
          description: row[3],
          creationDate: DateTime.tryParse(row[4]),
          otherUser: User(pseudoId: row[5]),
          otherCompany: Company(pseudoId: row[6], name: row[7]),
          reference: row[8],
          paymentMethod: row[9] != ''
              ? PaymentMethod(ccPaymentMethodId: 'check', checkNumber: row[9])
              : PaymentMethod(ccPaymentMethodId: 'cash'),
          paymentInstrument:
              row[9] == '' ? PaymentInstrument.cash : PaymentInstrument.check,
          grandTotal: row[10] != 'null' && row[10].isNotEmpty
              ? Decimal.parse(row[10].replaceAll(',', ''))
              : null,
          classificationId: row[11], // for invoice/payment matching
        ),
      );
    } catch (e) {
      String fieldList = '';
      finDocCsvTitles.asMap().forEach((index, value) =>
          fieldList += "$value: ${index < row.length ? row[index] : ''}\n");
      logger.e("Error processing findoc csv line:\n $fieldList \n"
          "error message: $e");
      if (errors++ == 5) exit(1);
    }
  }
  return finDocs;
}

// export
String CsvFromFinDocs(List<FinDoc> finDocs) {
  var csv = [finDocCsvFormat];
  for (FinDoc finDoc in finDocs) {
    csv.add(createCsvRow([
      finDoc.pseudoId ?? '',
      finDoc.docType.toString(),
      finDoc.sales.toString(),
      finDoc.description ?? '',
      finDoc.creationDate.toString(),
      finDoc.otherUser!.pseudoId ?? '',
      finDoc.otherCompany!.pseudoId!,
    ], finDocCsvLength));
  }
  return csv.join();
}
