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
  final List<Product> products;
  final int count;

  Products({this.products, this.count});
  @override
  List<Object> get props => [products, count];

  factory Products.fromJson(Map<String, dynamic> json) => Products(
      products:
          List<Product>.from(json["products"].map((x) => Product.fromJson(x))),
      count: int.parse(json["count"]));

  Map<String, dynamic> toJson() => {
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
        "count": count.toString,
      };
}

class Product extends Equatable {
  final String productId;
  final String productName;
  final String description;
  final Decimal price;
  final String categoryId;
  final String categoryName;
  final Uint8List image;

  Product({
    this.productId,
    this.productName,
    this.description,
    this.price,
    this.categoryId,
    this.categoryName,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: json["productId"],
        productName: json["productName"],
        description: json["description"],
        price: Decimal.parse(json["price"]),
        categoryId: json["categoryId"],
        categoryName: json["categoryName"],
        image: json["image"] != null ? base64.decode(json["image"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "productName": productName,
        "description": description,
        "price": price.toString(),
        "categoryId": categoryId,
        "categoryName": categoryName,
        "image": image != null ? base64.encode(image) : null,
      };

  @override
  List<Object> get props => [
        productId,
        productName,
        description,
        price,
        categoryId,
        categoryName,
        image
      ];

  @override
  String toString() => 'Product name: $productName[$productId] price: $price '
      'category: $categoryName[$categoryId] imgSize: ${image?.length}';
}
