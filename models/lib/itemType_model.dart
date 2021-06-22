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
//     final itemTypes = itemTypesFromJson(jsonString);
import 'dart:convert';
import 'package:equatable/equatable.dart';

List<ItemType> itemTypesFromJson(String str) => List<ItemType>.from(
    json.decode(str)["itemTypes"].map((x) => ItemType.fromJson(x)));
String itemTypesToJson(List<ItemType> data) =>
    '{"itemTypes":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class ItemType extends Equatable {
  final String itemTypeId;
  final String itemTypeName;

  ItemType({
    required this.itemTypeId,
    required this.itemTypeName,
  });

  factory ItemType.fromJson(Map<String, dynamic> json) => ItemType(
        itemTypeId: json["itemTypeId"] ?? '',
        itemTypeName: json["itemTypeName"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "itemTypeId": itemTypeId,
        "itemTypeName": itemTypeName,
      };

  @override
  String toString() {
    return 'Itemtype: $itemTypeName[$itemTypeId]';
  }

  @override
  List<Object?> get props => [itemTypeId, itemTypeName];
}
