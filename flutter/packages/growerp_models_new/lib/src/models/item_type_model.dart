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
import 'package:json_annotation/json_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

import '../create_csv_row.dart';
import 'models.dart';

part 'item_type_model.g.dart';

@JsonSerializable()
class ItemType {
  String itemTypeId;
  String itemTypeName;
  String accountCode;
  String accountName;

  ItemType({
    this.itemTypeId = '',
    this.itemTypeName = '',
    this.accountCode = '',
    this.accountName = '',
  });

  factory ItemType.fromJson(Map<String, dynamic> json) =>
      _$ItemTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ItemTypeToJson(this);

  @override
  String toString() => '$itemTypeName[$itemTypeId]';
}