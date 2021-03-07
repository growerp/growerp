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
import 'user_model.dart';

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

class FinDoc {
  String docType; // invoice, payment finDoc
  bool sales;
  String orderId;
  String invoiceId;
  String paymentId;
  String statusId;
  DateTime creationDate;
  DateTime completionDate;
  String description;
  User otherUser; //a single person responsible for finDoc of a single company
  Decimal grandTotal;
  List<FinDocItem> items;

  FinDoc({
    this.docType,
    this.sales,
    this.orderId,
    this.invoiceId,
    this.paymentId,
    this.statusId,
    this.creationDate,
    this.completionDate,
    this.description,
    this.otherUser,
    this.grandTotal,
    this.items,
  });

  factory FinDoc.fromJson(Map<String, dynamic> json) => FinDoc(
        docType: json["docType"],
        sales: json["sales"] == "true",
        orderId: json["orderId"],
        invoiceId: json["invoiceId"],
        paymentId: json["paymentId"],
        statusId: json["statusId"],
        creationDate: DateTime.tryParse(json["creationDate"] ?? ''),
        completionDate: DateTime.tryParse(json["completionDate"] ?? ''),
        description: json["description"],
        otherUser: User.fromJson(json["otherUser"]),
        grandTotal: Decimal.parse(json["grandTotal"]),
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
        "statusId": statusId,
        "creationDate": creationDate.toString(),
        "completionDate": completionDate.toString(),
        "description": description,
        "otherUser": otherUser == null ? null : otherUser.toJson(),
        "grandTotal": grandTotal.toString(),
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };

  String toString() =>
      "$docType# $orderId/$invoiceId/$paymentId s/p: ${sales ? 'sales' : 'purchase'} "
      "status: $statusId otherUser: $otherUser Items: ${items?.length}";
}

class FinDocItem {
  int itemSeqId;
  String itemTypeId;
  String productId;
  String description;
  Decimal quantity;
  Decimal price;

  FinDocItem({
    this.itemSeqId,
    this.itemTypeId,
    this.productId,
    this.description,
    this.quantity,
    this.price,
  });

  factory FinDocItem.fromJson(Map<String, dynamic> json) => FinDocItem(
        itemSeqId: int.parse(json["itemSeqId"]),
        itemTypeId: json["itemTypeId"],
        productId: json["productId"],
        description: json["description"],
        quantity: Decimal.parse(json["quantity"]),
        price: Decimal.parse(json["price"]),
      );

  Map<String, dynamic> toJson() => {
        "itemSeqId": itemSeqId.toString(),
        "itemTypeId": itemTypeId,
        "productId": productId,
        "description": description,
        "quantity": quantity.toString(),
        "price": price.toString(),
      };

  String toString() => 'FinDocItem: $itemSeqId product: $productId $price ';
}

Map<String, String> finDocStatusValues = {
  // explanation of status values
  'finDocPrep': 'in Preparation',
  'finDocCreated': 'Created',
  'finDocApproved': 'Approved',
  'finDocCompleted': 'Completed',
  'finDocCancelled': 'Cancelled'
};

Map<String, String> nextFinDocStatus = {
  // sequence of status values
  'finDocPrep': 'finDocCreated',
  'finDocCreated': 'finDocApproved',
  'finDocApproved': 'finDocCompleted',
};

Map<String, bool> finDocStatusFixed = {
  // if document can be updated
  'finDocPrep': true,
  'finDocCreated': true,
  'finDocApproved': true,
  'finDocCompleted': false,
  'finDocCancelled': false,
};
