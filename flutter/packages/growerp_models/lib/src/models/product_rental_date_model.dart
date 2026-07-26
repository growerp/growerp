/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
