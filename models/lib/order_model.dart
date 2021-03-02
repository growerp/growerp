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
//     final order = orderFromJson(jsonString);

import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'user_model.dart';

Order orderFromJson(String str) => Order.fromJson(json.decode(str)["order"]);
String orderToJson(Order data) =>
    '{"order":' + json.encode(data.toJson()) + "}";

List<Order> ordersFromJson(String str) =>
    List<Order>.from(json.decode(str)["orders"].map((x) => Order.fromJson(x)));
String ordersToJson(List<Order> data) =>
    '{"orders":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class Order {
  String orderId;
  String orderStatusId;
  DateTime placedDate;
  DateTime deliveryDate;
  String description;
  bool sales;
  User otherUser;
  Decimal grandTotal;
  String invoiceId;
  String paymentId;
  List<OrderItem> orderItems;

  Order({
    this.orderId,
    this.orderStatusId, // 'OrderOpen','OrderPlaced','OrderApproved', 'OrderCompleted', 'OrderCancelled'
    this.placedDate,
    this.deliveryDate,
    this.description,
    this.sales,
    this.otherUser,
    this.grandTotal,
    this.invoiceId,
    this.paymentId,
    this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json["orderId"],
        orderStatusId: json["orderStatusId"],
        placedDate: DateTime.tryParse(json["placedDate"] ?? ''),
        deliveryDate: DateTime.tryParse(json["deliveryDate"] ?? ''),
        description: json["description"],
        sales: json["sales"] == "true",
        otherUser: User.fromJson(json["otherUser"]),
        grandTotal: Decimal.parse(json["grandTotal"]),
        invoiceId: json["invoiceId"],
        paymentId: json["paymentId"],
        orderItems: List<OrderItem>.from(
            json["orderItems"].map((x) => OrderItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "orderId": orderId,
        "orderStatusId": orderStatusId,
        "placedDate": placedDate.toString(),
        "deliveryDate": deliveryDate.toString(),
        "description": description,
        "sales": sales.toString(),
        "otherUser": otherUser == null ? null : otherUser.toJson(),
        "grandTotal": grandTotal.toString(),
        "invoiceId": invoiceId,
        "paymentId": paymentId,
        "orderItems": List<dynamic>.from(orderItems.map((x) => x.toJson())),
      };

  String toString() => 'order# $orderId sales? $sales '
      ' ${deliveryDate != null ? deliveryDate.toString : ""} '
      'otherUser: $otherUser invoiceId: $invoiceId, paymentId: $paymentId'
      'orderItems: ${orderItems.length}';
}

class OrderItem {
  int orderItemSeqId;
  String itemTypeId;
  String productId;
  String description;
  Decimal quantity;
  Decimal price;

  OrderItem({
    this.orderItemSeqId,
    this.itemTypeId,
    this.productId,
    this.description,
    this.quantity,
    this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        orderItemSeqId: int.parse(json["orderItemSeqId"]),
        itemTypeId: json["itemTypeId"],
        productId: json["productId"],
        description: json["description"],
        quantity: Decimal.parse(json["quantity"]),
        price: Decimal.parse(json["price"]),
      );

  Map<String, dynamic> toJson() => {
        "orderItemSeqId": orderItemSeqId.toString(),
        "itemTypeId": itemTypeId,
        "productId": productId,
        "description": description,
        "quantity": quantity.toString(),
        "price": price.toString(),
      };

  String toString() => 'OrderItem: $orderItemSeqId product: $productId $price ';
}

List<String> orderStatusValues = [
  'OrderOpen',
  'OrderPlaced',
  'orderApproved',
  'OrderCompleted',
  'OrderCancelled'
];
Map nextOrderStatus = {
  'OrderOpen': 'OrderPlaced',
  'OrderPlaced': 'OrderApproved',
  'OrderApproved': 'OrderCompleted',
  'OrderCompleted': 'OrderCompleted',
  'OrderCancelled': 'OrderCancelled'
};
