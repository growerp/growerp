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
    //  this.reservations,
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
      };

  String toString() =>
      'Asset name: $assetName[$assetId] $productName[$productId $statusId]';

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
      ];

  Asset copyWith({
    String? assetId,
    String? assetClassId, // room, table etc
    String? assetName, // include room number/name
    String? statusId,
    Decimal? quantityOnHand,
    Decimal? availableToPromise,
    String? parentAssetId,
    String? productId,
    String? productName,
  }) =>
      Asset(
        assetId: assetId ?? this.assetId,
        assetClassId: assetClassId ?? this.assetClassId,
        assetName: assetName ?? this.assetName,
        statusId: statusId ?? this.statusId,
        quantityOnHand: quantityOnHand ?? this.quantityOnHand,
        availableToPromise: availableToPromise ?? this.availableToPromise,
        parentAssetId: parentAssetId ?? this.parentAssetId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
      );
}

List<String> assetClassIds = [
  'Hotel Room',
  'Restaurant Table',
  'Restaurant Table Area'
];

List<String> assetStatusValues = ['Available', 'Deactivated', 'In Use'];
