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

import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:growerp_models/src/json_converters.dart';
import '../create_csv_row.dart';
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

String productCsvFormat =
    'product Id, Type*, Name*, Description*, List Price*, Sales price*, '
    'Use Warehouse, Category 1, Category 2, Category 3, Image\r\n';
int productCsvLength = productCsvFormat.split(',').length;

List<Product> CsvToProducts(String csvFile) {
  List<Product> products = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    products.add(Product(
      pseudoId: row[0],
      productTypeId: row[1],
      productName: row[2],
      description: row[3],
      listPrice: Decimal.parse(row[4]),
      price: Decimal.parse(row[5]),
      useWarehouse: row[6] == 'true' ? true : false,
      categories: [
        Category(categoryName: row[7]),
        Category(categoryName: row[8]),
        Category(categoryName: row[9])
      ],
      image: row[10].isNotEmpty ? base64.decode(row[10]) : null,
    ));
  }
  return products;
}

String CsvFromProducts(List<Product> products) {
  var csv = [productCsvFormat];
  for (Product product in products) {
    csv.add(createCsvRow([
      product.pseudoId,
      product.productTypeId ?? '',
      product.productName ?? '',
      product.description ?? '',
      product.listPrice.toString(),
      product.price.toString(),
      product.useWarehouse.toString(),
      product.categories.length == 1 ? product.categories[0].categoryName : '',
      product.categories.length == 2 ? product.categories[1].categoryName : '',
      product.categories.length == 3 ? product.categories[2].categoryName : '',
      product.image != null ? base64.encode(product.image!) : '',
    ], productCsvLength));
  }
  return csv.join();
}
