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
//      product = productFromJson(jsonString);
//      products = productsFromJson(jsonString);

import 'dart:convert';
import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

Product productFromJson(String str) =>
    Product.fromJson(json.decode(str)["product"]);
String productToJson(Product data) =>
    '{"product":' + json.encode(data.toJson()) + "}";

List<Product> productsFromJson(String str) => List<Product>.from(
    json.decode(str)["products"].map((x) => Product.fromJson(x)));
String productsToJson(List<Product> data) =>
    '{"products":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class Products extends Equatable {
  final List<Product>? products;
  final int? count;

  Products({this.products, this.count});
  @override
  List<Object?> get props => [products, count];

  factory Products.fromJson(Map<String, dynamic> json) => Products(
      products:
          List<Product>.from(json["products"].map((x) => Product.fromJson(x))),
      count: int.parse(json["count"]));

  Map<String, dynamic> toJson() => {
        "products": List<dynamic>.from(products!.map((x) => x.toJson())),
        "count": count.toString,
      };
}

class Product extends Equatable {
  final String? productId;
  final String? productTypeId; // assetUse(rental)
  final String? assetClassId; // room, restaurant table
  final String? productName;
  final String? description;
  final Decimal? price;
  final String? categoryId;
  final String? categoryName;
  final int? assetCount;
  final Uint8List? image;

  Product({
    this.productId,
    this.productTypeId,
    this.assetClassId,
    this.productName,
    this.description,
    this.price,
    this.categoryId,
    this.categoryName,
    this.assetCount,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: json["productId"],
        productTypeId: json["productTypeId"],
        assetClassId: json["assetClassId"],
        productName: json["productName"],
        description: json["description"],
        price: json["price"] != null
            ? Decimal.parse(json["price"])
            : Decimal.parse("0.00"),
        categoryId: json["categoryId"],
        categoryName: json["categoryName"],
        assetCount:
            json["assetCount"] != null ? int.parse(json["assetCount"]) : 0,
        image: json["image"] != null ? base64.decode(json["image"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "productTypeId": productTypeId,
        "assetClassId": assetClassId,
        "productName": productName,
        "description": description,
        "price": price.toString(),
        "categoryId": categoryId,
        "categoryName": categoryName,
        "assetCount": assetCount.toString(),
        "image": image != null ? base64.encode(image!) : null,
      };

  @override
  List<Object?> get props => [
        productId,
        productTypeId,
        assetClassId,
        productName,
        description,
        price,
        categoryId,
        categoryName,
        assetCount,
        image
      ];

  @override
  String toString() => 'Product name: $productName[$productId] price: $price '
      'category: $categoryName[$categoryId] imgSize: ${image?.length}';

  Product copyWith({
    String? productId,
    String? productTypeId,
    String? assetClassId,
    String? productName,
    String? description,
    Decimal? price,
    String? categoryId,
    String? categoryName,
    Uint8List? image,
  }) =>
      Product(
        productId: productId ?? this.productId,
        productTypeId: productTypeId ?? this.productTypeId,
        assetClassId: assetClassId ?? this.assetClassId,
        productName: productName ?? this.productName,
        description: description ?? this.description,
        price: price ?? this.price,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        assetCount: this.assetCount,
        image: image ?? this.image,
      );
}

Map<String, String> productTypeIds = {
  'PtService': 'Service',
  'PtAsset': 'Physical Good',
  'PtAssetUse': 'Rental',
  'Service': 'PtService',
  'Physical Good': 'PtAsset',
  'Rental': 'PtAssetUse',
};
