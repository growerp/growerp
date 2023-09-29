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
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

import 'models.dart';

part 'product_model.g.dart';

@JsonSerializable()
class Product {
  String productId;
  String pseudoId;
  String? productTypeId; // good, service, assetUse(rental)
  String? assetClassId; // room, restaurant table
  String? productName;
  String? description;
  Decimal? listPrice;
  Decimal? price;
  List<Category> categories;
  bool useWarehouse;
  int? assetCount;
  @Uint8ListConverter()
  Uint8List? image;

  Product(
      {this.productId = '',
      this.pseudoId = '',
      this.productTypeId,
      this.assetClassId,
      this.productName,
      this.description,
      this.listPrice,
      this.price,
      this.categories = const [],
      this.useWarehouse = false,
      this.assetCount,
      this.image});

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  @override
  String toString() => '$productName[$productId]';
}

List<String> productTypes = ['Physical Good', 'Service', 'Rental'];
