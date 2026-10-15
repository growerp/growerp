import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin InventoryApi {
  // Inventory locations
  @GET("rest/s1/growerp/100/Location")
  Future<Locations> getLocation({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('filter') String? filter,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Location")
  Future<Location> createLocation({@Field() required Location location});

  @PATCH("rest/s1/growerp/100/Location")
  Future<Location> updateLocation({@Field() required Location location});

  @DELETE("rest/s1/growerp/100/Location")
  Future<Location> deleteLocation({@Field() required Location location});
}
