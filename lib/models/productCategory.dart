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

class ProductCategory {
  String categoryId;
  String categoryName;
  String preparationAreaId;
  String description;
  Uint8List image;

  ProductCategory({
    this.categoryId,
    this.categoryName,
    this.preparationAreaId,
    this.description,
    this.image,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        categoryId: json["categoryId"],
        categoryName: json["categoryName"],
        preparationAreaId: json["preparationAreaId"],
        description: json["description"],
        image: json["image"] != null ? base64.decode(json["image"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "categoryId": categoryId,
        "categoryName": categoryName,
        "preparationAreaId": preparationAreaId,
        "description": description,
        "image": image != null ? base64.encode(image) : null,
      };

  String toString() => 'ProductCategory name: $categoryName[$categoryId]';
}
