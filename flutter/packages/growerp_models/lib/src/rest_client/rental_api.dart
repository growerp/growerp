import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin RentalApi {
  // HOTEL: date-banded room rates
  @GET("rest/s1/growerp/100/RentalPrice")
  Future<RentalPrices> getRentalPrices({
    @Query('productId') required String productId,
  });

  @POST("rest/s1/growerp/100/RentalPrice")
  Future<RentalPrice> createRentalPrice(
    @Body() Map<String, dynamic> rentalPrice,
  );

  @PATCH("rest/s1/growerp/100/RentalPrice")
  Future<void> updateRentalPrice(@Body() Map<String, dynamic> rentalPrice);

  @DELETE("rest/s1/growerp/100/RentalPrice")
  Future<void> deleteRentalPrice({
    @Query('rentalPriceId') required String rentalPriceId,
  });

  // HOTEL: stay quote (nightly rates + tourist tax)
  @GET("rest/s1/growerp/100/RentalQuote")
  Future<RentalQuote> getRentalQuote({
    @Query('productId') required String productId,
    @Query('fromDate') required String fromDate,
    @Query('nights') required int nights,
    @Query('quantity') int? quantity,
  });

  // HOTEL: housekeeping board
  @GET("rest/s1/growerp/100/Housekeeping")
  Future<HotelRooms> getHousekeeping({
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @PATCH("rest/s1/growerp/100/Housekeeping")
  Future<HotelRoom> updateHousekeeping({
    @Query('assetId') required String assetId,
    @Query('hkStatusId') required String hkStatusId,
  });

  /// mark all rooms clean at the end of a housekeeping round
  @POST("rest/s1/growerp/100/Housekeeping")
  Future<void> resetHousekeeping();

  // HOTEL: occupancy / ADR / RevPAR statistics
  @GET("rest/s1/growerp/100/HotelStatistics")
  Future<HotelStatistics> getHotelStatistics({
    @Query('fromDate') String? fromDate,
    @Query('thruDate') String? thruDate,
    @Query('assetClassId') String? assetClassId,
  });
}
