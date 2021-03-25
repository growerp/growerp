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
//      category = categoryFromJson(jsonString);

import 'dart:convert';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';

ProductCategory categoryFromJson(String str) =>
    ProductCategory.fromJson(json.decode(str)["category"]);
String categoryToJson(ProductCategory data) =>
    '{"category":' + json.encode(data.toJson()) + "}";

List<ProductCategory> categoriesFromJson(String str) =>
    List<ProductCategory>.from(
        json.decode(str)["categories"].map((x) => ProductCategory.fromJson(x)));
String categoriesToJson(List<ProductCategory> data) =>
    '{"categories":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class ProductCategory extends Equatable {
  final String? categoryId;
  final String? categoryName;
  final String? description;
  final Uint8List? image;
  final int? nbrOfProducts;

  ProductCategory(
      {this.categoryId,
      this.categoryName,
      this.description,
      this.image,
      this.nbrOfProducts});

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
          categoryId: json["categoryId"],
          categoryName: json["categoryName"],
          description: json["description"],
          image: json["image"] != null ? base64.decode(json["image"]) : null,
          nbrOfProducts: json['nbrOfProducts']);

  Map<String, dynamic> toJson() => {
        "categoryId": categoryId,
        "categoryName": categoryName,
        "description": description,
        "image": image != null ? base64.encode(image!) : null,
      };

  @override
  List<Object?> get props =>
      [categoryId, categoryName, description, image, nbrOfProducts];

  @override
  String toString() => 'ProductCategory name: $categoryName[$categoryId]';

  ProductCategory copyWith({
    String? categoryId,
    String? categoryName,
    String? description,
    Uint8List? image,
    int? nbrOfProducts,
  }) =>
      ProductCategory(
          categoryId: categoryId ?? this.categoryId,
          categoryName: categoryName ?? this.categoryName,
          description: description ?? this.description,
          image: image ?? this.image,
          nbrOfProducts: nbrOfProducts ?? nbrOfProducts);
}
