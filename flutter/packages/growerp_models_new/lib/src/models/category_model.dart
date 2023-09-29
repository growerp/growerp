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
import 'package:json_annotation/json_annotation.dart';
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
