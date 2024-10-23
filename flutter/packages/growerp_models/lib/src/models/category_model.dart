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
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

import '../create_csv_row.dart';
import 'models.dart';
import '../json_converters.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
class Category extends Equatable with _$Category {
  Category._();
  factory Category({
    @Default("") String categoryId,
    @Default("") String pseudoId,
    @Default("") String categoryName,
    @Default("") String description,
    @Uint8ListConverter() Uint8List? image,
    @Default(0) int seqId,
    @Default(0) int nbrOfProducts,
    @Default([]) List<Product> products,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json['category'] ?? json);

  @override
  List<Object?> get props => [categoryId];

  @override
  String toString() => '$categoryName[$categoryId]';
}

String categoryCsvFormat =
    "category Id, Category Name*, Description*, image\r\n";
int categoryCsvLength = categoryCsvFormat.split(',').length;

List<Category> csvToCategories(String csvFile) {
  List<Category> categories = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    categories.add(
      Category(
          categoryId: row[0],
          categoryName: row[1],
          description: row[2],
          image:
              row[3].isNotEmpty ? Uint8List.fromList(row[3].codeUnits) : null),
    );
  }

  return categories;
}

String csvFromCategories(List<Category> categories) {
  var csv = [categoryCsvFormat];
  for (Category category in categories) {
    csv.add(createCsvRow([
      category.categoryId,
      category.categoryName,
      category.description,
      category.image != null ? category.image!.toList().toString() : '',
    ], categoryCsvLength));
  }
  return csv.join();
}
