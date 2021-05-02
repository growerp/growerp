/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
//     final ganntLines = ganntLinesFromJson(jsonString);

import 'dart:convert';

import 'finDoc_model.dart';

List<GanntLine> ganntLinesFromJson(String str) => List<GanntLine>.from(
    json.decode(str)["ganntLines"].map((x) => GanntLine.fromJson(x)));

String ganntLinesToJson(List<GanntLine> data) =>
    '{"ganntLines:"' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class GanntLine {
  GanntLine({
    this.finDoc,
    this.assetId,
    this.assetName,
    this.productId,
    this.fromDate,
    this.thruDate,
    this.customerPartyId,
    this.customerName,
  });

  final FinDoc? finDoc;
  final String? assetId;
  final String? assetName;
  final String? productId;
  final DateTime? fromDate;
  final DateTime? thruDate;
  final String? customerPartyId;
  final String? customerName;

  factory GanntLine.fromJson(Map<String, dynamic> json) => GanntLine(
        finDoc: json["finDoc"],
        assetId: json["assetId"],
        assetName: json["assetName"],
        productId: json["productId"],
        fromDate:
            json["fromDate"] != null ? DateTime.parse(json["fromDate"]) : null,
        thruDate:
            json["thruDate"] != null ? DateTime.parse(json["thruDate"]) : null,
        customerPartyId: json["customerPartyId"],
        customerName: json["customerName"],
      );

  Map<String, dynamic> toJson() => {
        "finDoc": finDoc,
        "assetId": assetId,
        "assetName": assetName,
        "productId": productId,
        "fromDate": fromDate.toString(),
        "thruDate": thruDate.toString(),
        "customerPartyId": customerPartyId,
        "customerName": customerName,
      };
//  @override
//  String toString() =>
//      "ganntLine, finDocId: ${finDoc!.id() ?? null} fromDate: ${fromDate ?? null}";
}
