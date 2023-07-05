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

part 'full_dates_product_rental_model.freezed.dart';
part 'full_dates_product_rental_model.g.dart';

/// data model used to obtain all dates where a [Product] i.e. room type
/// is fully booked over all assets connected.
@freezed
class FullDatesProductRental extends Equatable with _$FullDatesProductRental {
  FullDatesProductRental._();
  factory FullDatesProductRental({
    @Default("") String productId,
    @Default("") String productName,
    @Default([]) List<String> fullDates,
  }) = _FullDatesProductRental;

  factory FullDatesProductRental.fromJson(Map<String, dynamic> json) =>
      _$FullDatesProductRentalFromJson(json);

  @override
  List<Object?> get props => [productId, productName];

  @override
  String toString() => '$productName[$productId] dates: ${fullDates.length}';
}
