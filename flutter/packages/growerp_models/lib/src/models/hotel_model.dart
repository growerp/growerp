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

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../growerp_models.dart';

part 'hotel_model.freezed.dart';
part 'hotel_model.g.dart';

/// A date-banded rental rate for a room type (rental product). When no band
/// covers a night the product current price is used.
@freezed
abstract class RentalPrice with _$RentalPrice {
  factory RentalPrice({
    @Default('') String rentalPriceId,
    @Default('') String productId,
    @DateTimeConverter() DateTime? fromDate,
    @DateTimeConverter() DateTime? thruDate,
    Decimal? price,
  }) = _RentalPrice;
  RentalPrice._();

  factory RentalPrice.fromJson(Map<String, dynamic> json) =>
      _$RentalPriceFromJson(json['rentalPrice'] ?? json);
}

@freezed
abstract class RentalPrices with _$RentalPrices {
  factory RentalPrices({@Default([]) List<RentalPrice> rentalPrices}) =
      _RentalPrices;
  RentalPrices._();

  factory RentalPrices.fromJson(Map<String, dynamic> json) =>
      _$RentalPricesFromJson(json);
}

/// A single night's rate within a stay quote.
@freezed
abstract class NightlyRate with _$NightlyRate {
  factory NightlyRate({
    @Default('') String date,
    Decimal? price,
  }) = _NightlyRate;
  NightlyRate._();

  factory NightlyRate.fromJson(Map<String, dynamic> json) =>
      _$NightlyRateFromJson(json);
}

/// The computed price of a stay: per-night rates, room total, tourist tax
/// and grand total. Returned by the `RentalQuote` service.
@freezed
abstract class RentalQuote with _$RentalQuote {
  factory RentalQuote({
    @Default([]) List<NightlyRate> nightlyRates,
    Decimal? roomTotal,
    Decimal? touristTax,
    Decimal? grandTotal,
    Decimal? averageNightlyRate,
  }) = _RentalQuote;
  RentalQuote._();

  factory RentalQuote.fromJson(Map<String, dynamic> json) =>
      _$RentalQuoteFromJson(json['rentalQuote'] ?? json);
}

/// A hotel room row for the housekeeping board.
@freezed
abstract class HotelRoom with _$HotelRoom {
  factory HotelRoom({
    @Default('') String assetId,
    @Default('') String pseudoId,
    String? assetName,
    String? productName,
    @Default('Clean') String hkStatusId, // Clean / Dirty
    @Default(false) bool occupied,
  }) = _HotelRoom;
  HotelRoom._();

  factory HotelRoom.fromJson(Map<String, dynamic> json) =>
      _$HotelRoomFromJson(json['room'] ?? json);
}

@freezed
abstract class HotelRooms with _$HotelRooms {
  factory HotelRooms({@Default([]) List<HotelRoom> rooms}) = _HotelRooms;
  HotelRooms._();

  factory HotelRooms.fromJson(Map<String, dynamic> json) =>
      _$HotelRoomsFromJson(json);
}

/// Occupancy / ADR / RevPAR statistics for a date range.
@freezed
abstract class HotelStatistics with _$HotelStatistics {
  factory HotelStatistics({
    String? fromDate,
    String? thruDate,
    @Default(0) int totalRooms,
    @Default(0) int availableRoomNights,
    @Default(0) int occupiedRoomNights,
    Decimal? occupancyPercent,
    Decimal? roomRevenue,
    Decimal? adr,
    Decimal? revPar,
  }) = _HotelStatistics;
  HotelStatistics._();

  factory HotelStatistics.fromJson(Map<String, dynamic> json) =>
      _$HotelStatisticsFromJson(json['hotelStatistics'] ?? json);
}
