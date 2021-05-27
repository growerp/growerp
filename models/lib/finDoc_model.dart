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

// To parse this JSON data, do
//
//     final finDoc = finDocFromJson(jsonString);

import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '@models.dart';

FinDoc finDocFromJson(String str) =>
    FinDoc.fromJson(json.decode(str)["finDoc"]);
String finDocToJson(FinDoc data) =>
    '{"finDoc":' + json.encode(data.toJson()) + "}";

List<FinDoc> finDocsFromJson(String str) => List<FinDoc>.from(
    json.decode(str)["finDocs"].map((x) => FinDoc.fromJson(x)));
String finDocsToJson(List<FinDoc> data) =>
    '{"finDocs":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class FinDoc extends Equatable {
  final String? docType; // invoice, payment etc
  final bool? sales;
  final String? orderId;
  final String? invoiceId;
  final String? paymentId;
  final String? transactionId;
  final String? statusId;
  final DateTime? creationDate;
  final DateTime? placedDate;
  final String? description;
  final User?
      otherUser; //a single person responsible for finDoc of a single company
  final Decimal? grandTotal;
  final String? classificationId; // is productStore
  final List<FinDocItem>? items;

  FinDoc({
    this.docType,
    this.sales,
    this.orderId,
    this.invoiceId,
    this.paymentId,
    this.transactionId,
    this.statusId,
    this.creationDate,
    this.placedDate,
    this.description,
    this.otherUser,
    this.grandTotal,
    this.classificationId,
    this.items,
  });

  factory FinDoc.fromJson(Map<String, dynamic> json) => FinDoc(
        docType: json["docType"],
        sales: json["sales"] == null ? null : json["sales"] == "true",
        orderId: json["orderId"],
        invoiceId: json["invoiceId"],
        paymentId: json["paymentId"],
        transactionId: json["transactionId"],
        statusId: json["statusId"],
        creationDate: DateTime.tryParse(json["creationDate"] ?? ''),
        placedDate: DateTime.tryParse(json["placedDate"] ?? ''),
        description: json["description"],
        otherUser:
            json["otherUser"] == null ? null : User.fromJson(json["otherUser"]),
        grandTotal: json["grandTotal"] != null
            ? Decimal.parse(json["grandTotal"])
            : Decimal.parse("0"),
        classificationId: json["classificationId"],
        items: json["items"] == null
            ? []
            : List<FinDocItem>.from(
                json["items"].map((x) => FinDocItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "docType": docType,
        "sales": sales.toString(),
        "orderId": orderId,
        "invoiceId": invoiceId,
        "paymentId": paymentId,
        "transactionId": transactionId,
        "statusId": statusId,
        "creationDate": creationDate.toString(),
        "placedDate": placedDate.toString(),
        "description": description,
        "otherUser": otherUser == null ? null : otherUser!.toJson(),
        "grandTotal": grandTotal.toString(),
        "classificationId": classificationId,
        "items": List<dynamic>.from(items!.map((x) => x.toJson())),
      };

  bool idIsNull() => (invoiceId == null &&
          orderId == null &&
          paymentId == null &&
          transactionId == null)
      ? true
      : false;

  String salesString() =>
      sales != null ? (sales == true ? 'Sales' : 'Purchase') : 'all';

  String? id() => idIsNull()
      ? 'New'
      : docType == 'order'
          ? orderId
          : docType == 'payment'
              ? paymentId
              : docType == 'invoice'
                  ? invoiceId
                  : docType == 'transaction'
                      ? transactionId
                      : null;

  @override
  List<Object?> get props => [
        docType, // invoice, payment etc
        sales,
        orderId,
        invoiceId,
        paymentId,
        transactionId,
        statusId,
        creationDate,
        placedDate,
        description,
        otherUser, //a single person responsible for finDoc of a single company
        grandTotal,
        items,
      ];

  List<String?> otherIds() =>
      docType == 'order' ? ['invoice', invoiceId, 'payment', paymentId] : [];

  String toString() =>
      "$docType# $orderId!/$invoiceId!/$paymentId! s/p: ${salesString()} "
      "Descr: $description! "
      "status: $statusId! otherUser: $otherUser! Items: ${items!.length}";

  FinDoc copyWith({
    String? docType, // invoice, payment etc
    bool? sales,
    String? orderId,
    String? invoiceId,
    String? paymentId,
    String? transactionId,
    String? statusId,
    DateTime? creationDate,
    DateTime? placedDate,
    String? description,
    User?
        otherUser, //a single person responsible for finDoc of a single company
    Decimal? grandTotal,
    String? classificationId,
    List<FinDocItem>? items,
  }) =>
      FinDoc(
        docType: docType ?? this.docType,
        sales: sales ?? this.sales,
        orderId: orderId ?? this.orderId,
        invoiceId: invoiceId ?? this.invoiceId,
        paymentId: paymentId ?? this.paymentId,
        transactionId: transactionId ?? this.transactionId,
        statusId: statusId ?? this.statusId,
        creationDate: creationDate ?? this.creationDate,
        placedDate: placedDate ?? this.placedDate,
        description: description ?? this.description,
        otherUser: otherUser ?? this.otherUser,
        grandTotal: grandTotal ?? this.grandTotal,
        classificationId: classificationId ?? this.classificationId,
        items: items ?? this.items,
      );
}

class FinDocItem extends Equatable {
  final int? itemSeqId;
  final String? itemTypeId;
  final String? productId;
  final String? description;
  final Decimal? quantity;
  final Decimal? price;
  final String? glAccountId;
  final String? assetId;
  final String? assetName;
  final DateTime? rentalFromDate;
  final DateTime? rentalThruDate;

  FinDocItem({
    this.itemSeqId,
    this.itemTypeId,
    this.productId,
    this.description,
    this.quantity,
    this.price,
    this.glAccountId,
    this.assetId,
    this.assetName,
    this.rentalFromDate,
    this.rentalThruDate,
  });

  factory FinDocItem.fromJson(Map<String, dynamic> json) => FinDocItem(
        itemSeqId: int.parse(json["itemSeqId"]),
        itemTypeId: json["itemTypeId"],
        productId: json["productId"],
        description: json["description"],
        quantity:
            json["quantity"] != null ? Decimal.parse(json["quantity"]) : null,
        price: json["price"] != null
            ? Decimal.parse(json["price"])
            : Decimal.parse("0"),
        glAccountId: json["glAccountId"],
        assetId: json["assetId"],
        assetName: json["assetName"],
        rentalFromDate: DateTime.tryParse(json["rentalFromDate"] ?? ''),
        rentalThruDate: DateTime.tryParse(json["rentalThruDate"] ?? ''),
      );

  Map<String, dynamic> toJson() => {
        "itemSeqId": itemSeqId.toString(),
        "itemTypeId": itemTypeId,
        "productId": productId,
        "description": description,
        "quantity": quantity.toString(),
        "price": price.toString(),
        "glAccountId": glAccountId,
        "assetId": assetId,
        "assetname": assetName,
        "rentalFromDate": rentalFromDate.toString(),
        "rentalThruDate": rentalThruDate.toString(),
      };

  String toString() =>
      'FinDocItem: $itemSeqId product: $productId $price ${rentalFromDate.toString()}';

  @override
  List<Object?> get props => [
        itemSeqId,
        itemTypeId,
        productId,
        description,
        quantity,
        price,
        glAccountId,
        assetId,
        assetName,
        rentalFromDate,
        rentalThruDate,
      ];

  FinDocItem copyWith({
    int? itemSeqId,
    String? itemTypeId,
    String? productId,
    String? description,
    Decimal? quantity,
    Decimal? price,
    String? glAccountId,
    String? assetId,
    String? assetName,
    DateTime? rentalFromDate,
    DateTime? rentalThruDate,
  }) =>
      FinDocItem(
        itemSeqId: itemSeqId ?? this.itemSeqId,
        itemTypeId: itemTypeId ?? this.itemTypeId,
        productId: productId ?? this.productId,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        glAccountId: glAccountId ?? this.glAccountId,
        assetId: assetId ?? this.assetId,
        assetName: assetName ?? this.assetName,
        rentalFromDate: rentalFromDate ?? this.rentalFromDate,
        rentalThruDate: rentalThruDate ?? this.rentalThruDate,
      );
}

Map<String, String> finDocStatusValues = {
  // explanation of status values
  'FinDocPrep': 'in Preparation',
  'FinDocCreated': 'Created',
  'FinDocApproved': 'Approved',
  'FinDocCompleted': 'Completed',
  'FinDocCancelled': 'Cancelled'
};

Map<String, String> nextFinDocStatus = {
  // sequence of status values
  'FinDocPrep': 'FinDocCreated',
  'FinDocCreated': 'FinDocApproved',
  'FinDocApproved': 'FinDocCompleted',
};

Map<String, bool> finDocStatusFixed = {
  // if document can be updated
  'FinDocPrep': true,
  'FinDocCreated': true,
  'FinDocApproved': false,
  'FinDocCompleted': false,
  'FinDocCancelled': false,
};
