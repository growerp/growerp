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

import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/src/json_converters.dart';
import 'models.dart';
part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class Product extends Equatable with _$Product {
  Product._();
  factory Product({
    @Default("") String productId,
    @Default("") String pseudoId,
    String? productTypeId, // good, service, assetUse(rental)
    String? assetClassId, // room, restaurant table
    String? productName,
    String? description,
    Decimal? listPrice,
    Decimal? price,
    @Default([]) List<Category> categories,
    @Default(false) bool useWarehouse,
    int? assetCount,
    @Uint8ListConverter() Uint8List? image,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  @override
  List<Object?> get props => [productId];

  @override
  String toString() => '$productName[$productId]';
}

List<String> productTypes = ['Physical Good', 'Service', 'Rental'];
