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
import 'package:freezed_annotation/freezed_annotation.dart';
part 'product_rental_date_model.freezed.dart';
part 'product_rental_date_model.g.dart';

/// This model is used to represent rental dates for products
@freezed
abstract class ProductRentalDate extends Equatable with _$ProductRentalDate {
  const ProductRentalDate._();
  const factory ProductRentalDate({
    @Default("") String productId,
    String? productName,
    @Default([]) List<DateTime> dates,
  }) = _ProductRentalDate;

  factory ProductRentalDate.fromJson(Map<String, dynamic> json) =>
      _$ProductRentalDateFromJson(json['productRentalDate'] ?? json);

  @override
  List<Object?> get props => [productId];

  @override
  String toString() => '$productName[$productId] #dates: ${dates.length}';
}
