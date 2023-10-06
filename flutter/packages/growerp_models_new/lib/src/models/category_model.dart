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

part 'category_model.g.dart';

@JsonSerializable()
class Category {
  String categoryId;
  String categoryName;
  String description;
  @Uint8ListConverter()
  Uint8List? image;
  int seqId;
  int nbrOfProducts;
  List<Product> products;

  Category(
      {this.categoryId = '',
      this.categoryName = '',
      this.description = '',
      this.seqId = 0,
      this.image,
      this.nbrOfProducts = 0,
      this.products = const []});

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  @override
  String toString() => '$categoryName[$categoryId]';
}

String CategoryCsvFormat() =>
    "category Id, Category Name*, Description*, image\r\n";

List<String> CategoryCsvToJson(String csvFile) {
  List<String> categories = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    categories.add(jsonEncode(Category(
            categoryId: row[0],
            categoryName: row[1],
            description: row[1],
            image:
                row[3].isNotEmpty ? Uint8List.fromList(row[3].codeUnits) : null)
        .toJson()));
  }

  return categories;
}

String CsvFromCategories(List<Category> categories) {
//  final l = json.decode(result)['categories'] as Iterable;
//  List<Category> categories = List<Category>.from(
//      l.map((e) => Category.fromJson(e as Map<String, dynamic>)));
  var csv = [];
  for (Category category in categories) {
    csv.add(createCsvRow([
      category.categoryId,
      category.categoryName,
      category.description,
      category.image != null ? category.image!.toList().toString() : '',
    ]));
  }
  return csv.join();
}
