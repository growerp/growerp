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
//      asset = assetFromJson(jsonString);

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

Asset assetFromJson(String str) => Asset.fromJson(json.decode(str)["asset"]);
String assetToJson(Asset data) =>
    '{"asset":' + json.encode(data.toJson()) + "}";

List<Asset> assetsFromJson(String str) =>
    List<Asset>.from(json.decode(str)["assets"].map((x) => Asset.fromJson(x)));
String assetsToJson(List<Asset> data) =>
    '{"assets":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

// backend relation: product -> asset -> assetReservation -> orderItem

class Asset extends Equatable {
  final String? assetId;
  final String? assetClassId; // room, table etc
  final String? assetName; // include room number/name
  final String? statusId;
  final Decimal? quantityOnHand;
  final Decimal? availableToPromise;
  final String? parentAssetId;
  final String? productId;
  final String? productName;
  final List<Reservation>? reservations;

  Asset({
    this.assetId,
    this.assetClassId,
    this.assetName,
    this.statusId,
    this.quantityOnHand,
    this.availableToPromise,
    this.parentAssetId,
    this.productId,
    this.productName,
    this.reservations,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        assetId: json["assetId"],
        assetClassId: json["assetClassId"],
        assetName: json["assetName"],
        statusId: json["statusId"],
        quantityOnHand: json["quantityOnHand"] != null
            ? Decimal.parse(json["quantityOnHand"])
            : Decimal.parse("0"),
        availableToPromise: json["availableToPromise"] != null
            ? Decimal.parse(json["availableToPromise"])
            : Decimal.parse("0"),
        parentAssetId: json["parentAssetId"],
        productId: json["productId"],
        productName: json["productName"],
        reservations: json["reservations"] == null
            ? []
            : List<Reservation>.from(
                json["reservations"].map((x) => Reservation.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "assetId": assetId,
        "assetClassId": assetClassId,
        "assetName": assetName,
        "statusId": statusId,
        "quantityOnHand": quantityOnHand.toString(),
        "availableToPromise": availableToPromise.toString(),
        "parentAssetId": parentAssetId,
        "productId": productId,
        "productName": productName,
        "reservations": reservations != null
            ? List<dynamic>.from(reservations!.map((x) => x.toJson()))
            : null,
      };

  String toString() =>
      'Asset name: $assetName[$assetId] $productName[$productId]';

  @override
  List<Object?> get props => [
        assetId,
        assetClassId,
        assetName,
        statusId,
        quantityOnHand,
        availableToPromise,
        parentAssetId,
        productId,
        productName,
        reservations,
      ];
}

class Reservation extends Equatable {
  final String? reservationId;
  final String? orderId;
  final String? orderItemSeqId;
  final String? productId;
  final String? assetId;
  final DateTime? rentalFromDate;
  final DateTime? rentalThruDate;

  Reservation({
    this.reservationId,
    this.orderId,
    this.orderItemSeqId,
    this.productId,
    this.assetId,
    this.rentalFromDate,
    this.rentalThruDate,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        reservationId: json["reservationId"],
        orderId: json["orderId"],
        orderItemSeqId: json["orderItemSeqId"],
        productId: json["productId"],
        assetId: json["assetId"],
        rentalFromDate: json["rentalFromDate"] != null
            ? DateTime.tryParse(json["rentalFromDate"] ?? '')
            : null,
        rentalThruDate: json["rentalThruDate"] != null
            ? DateTime.tryParse(json["rentalThruDate"] ?? '')
            : null,
      );

  Map<String, dynamic> toJson() => {
        "reservationId": reservationId.toString(),
        "orderId": orderItemSeqId,
        "orderItemSeqId": orderItemSeqId,
        "productId": productId,
        "assetId": assetId,
        "rentalFromDate": rentalFromDate.toString(),
        "rentalThruDate": rentalThruDate.toString(),
      };

  String toString() =>
      'Reservation: $reservationId product: $productId ${rentalFromDate.toString()} ';

  @override
  List<Object?> get props => [
        reservationId,
        orderId,
        orderItemSeqId,
        productId,
        assetId,
        rentalFromDate,
        rentalThruDate,
      ];

  Reservation copyWith({
    String? reservationId,
    String? orderId,
    String? orderItemSeqId,
    String? productId,
    String? assetId,
    DateTime? rentalFromDate,
    DateTime? rentalThruDate,
  }) =>
      Reservation(
        reservationId: reservationId ?? this.reservationId,
        orderId: orderId ?? this.orderId,
        orderItemSeqId: orderItemSeqId ?? this.orderItemSeqId,
        productId: productId ?? this.productId,
        assetId: assetId ?? this.assetId,
        rentalFromDate: rentalFromDate ?? this.rentalFromDate,
        rentalThruDate: rentalThruDate ?? this.rentalThruDate,
      );
}

Map<String, String> assetClassIds = {
  'Hotel Room': 'AsClsRoom',
  'Restaurant Table': 'AsClsTable',
  'Restaurant Table Area': 'AsClsTableArea',
  'AsClsRoom': 'Hotel Room',
  'AsClsTable': 'Restaurant Table',
  'AsClsTableArea': 'Restaurant Table Area',
};

List<String> assetStatusValues = ['Available', 'Deactivated', 'In Use'];

Map<String, String> assetStatusses = {
  'Available': 'AstAvailable',
  'Deactivated': 'AstDeactivated',
  'In Use': 'AstInUse',
  'AstAvailable': 'Available',
  'AstDeactivated': 'Deactivated',
  'AstInUse': 'In Use',
};
