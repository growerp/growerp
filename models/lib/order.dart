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
  String placedDate;
  String placedTime;
  String customerPartyId;
  String firstName;
  String lastName;
  String email;
  Decimal grandTotal;
  String table;
  String accommodationAreaId;
  String accommodationSpotId;
  List<OrderItem> orderItems;

  Order({
    this.orderId,
    this.orderStatusId, // 'OrderOpen','OrderPlaced','OrderApproved', 'OrderCompleted', 'OrderCancelled'
    this.placedDate,
    this.placedTime,
    this.customerPartyId,
    this.firstName,
    this.lastName,
    this.email,
    this.grandTotal,
    this.table,
    this.accommodationAreaId,
    this.accommodationSpotId,
    this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json["orderId"],
        orderStatusId: json["orderStatusId"],
        placedDate: json["placedDate"],
        placedTime: json["placedTime"],
        customerPartyId: json["customerPartyId"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        email: json["email"],
        grandTotal: Decimal.parse(json["grandTotal"]),
        accommodationAreaId: json["accommodationAreaId"],
        accommodationSpotId: json["accommodationSpotId"],
        orderItems: List<OrderItem>.from(
            json["orderItems"].map((x) => OrderItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "orderId": orderId,
        "orderStatusId": orderStatusId,
        "placedDate": placedDate,
        "placedTime": placedTime,
        "customerPartyId": customerPartyId,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "grandTotal": grandTotal.toString(),
        "table": table,
        "accommodationAreaId": accommodationAreaId,
        "accommodationSpotId": accommodationSpotId,
        "orderItems": List<dynamic>.from(orderItems.map((x) => x.toJson())),
      };

  String toString() => 'order# $orderId customer: $customerPartyId items: '
      '${orderItems?.length} firstItem ${orderItems[0]}';
}

class OrderItem {
  OrderItem({
    this.orderItemSeqId,
    this.productId,
    this.description,
    this.quantity,
    this.price,
  });

  int orderItemSeqId;
  String productId;
  String description;
  Decimal quantity;
  Decimal price;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
      orderItemSeqId: int.parse(json["orderItemSeqId"]),
      productId: json["productId"],
      description: json["description"],
      quantity: Decimal.parse(json["quantity"]),
      price: Decimal.parse(json["price"]));

  Map<String, dynamic> toJson() => {
        "orderItemSeqId": orderItemSeqId.toString(),
        "productId": productId,
        "description": description,
        "quantity": quantity.toString(),
        "price": price.toString()
      };

  String toString() => 'OrderItem: $orderItemSeqId product: $productId $price ';
}
