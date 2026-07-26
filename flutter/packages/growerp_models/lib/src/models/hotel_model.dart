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
