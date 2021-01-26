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
//     final catalog = catalogFromJson(jsonString);

import '@models.dart';
import 'dart:convert';

Catalog catalogFromJson(String str) => Catalog.fromJson(json.decode(str));
String catalogToJson(Catalog data) => json.encode(data.toJson());

class Catalog {
  List<ProductCategory> categories;
  List<Product> products;

  Catalog({
    this.categories,
    this.products,
  });

  ProductCategory getByProductCategoryId(String id) =>
      categories.firstWhere((element) => element.categoryId == id);
  ProductCategory getByProductCategoryPosition(int position) =>
      categories[position % 2];

  Product getByProductId(String id) =>
      products.firstWhere((element) => element.productId == id);
  Product getByProductPosition(int position) => products[position % 2];

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
        categories: json["categories"] != null
            ? List<ProductCategory>.from(
                json["categories"].map((x) => ProductCategory.fromJson(x)))
            : null,
        products: json["products"] != null
            ? List<Product>.from(
                json["products"].map((x) => Product.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
      };

  String toString() =>
      'CatalogLoaded, categories: ${categories?.length}' +
      ' products: ${products?.length}';
}
