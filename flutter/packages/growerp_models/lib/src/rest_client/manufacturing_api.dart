import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin ManufacturingApi {
  // manufacturing
  @GET("rest/s1/growerp/100/Boms")
  Future<Boms> getBoms({
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/BomItems")
  Future<BomItems> getBomItem({
    @Query('productId') String? productId,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/BomItem")
  Future<BomItem> createBomItem({@Field() required BomItem bomItem});

  @PATCH("rest/s1/growerp/100/BomItem")
  Future<BomItem> updateBomItem({@Field() required BomItem bomItem});

  @DELETE("rest/s1/growerp/100/BomItem")
  Future<BomItem> deleteBomItem({@Field() required BomItem bomItem});

  @GET("rest/s1/growerp/100/WorkOrders")
  Future<WorkOrders> getWorkOrder({
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/WorkOrder")
  Future<WorkOrder> createWorkOrder({@Field() required WorkOrder workOrder});

  @PATCH("rest/s1/growerp/100/WorkOrder")
  Future<WorkOrder> updateWorkOrder({@Field() required WorkOrder workOrder});

  @DELETE("rest/s1/growerp/100/WorkOrder")
  Future<WorkOrder> deleteWorkOrder({@Field() required WorkOrder workOrder});

  // routing
  @GET("rest/s1/growerp/100/Routings")
  Future<Routings> getRoutings({
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Routing")
  Future<Routing> createRouting({@Field() required Routing routing});

  @PATCH("rest/s1/growerp/100/Routing")
  Future<Routing> updateRouting({@Field() required Routing routing});

  @DELETE("rest/s1/growerp/100/Routing")
  Future<Routing> deleteRouting({@Field() required Routing routing});

  @GET("rest/s1/growerp/100/RoutingTasks")
  Future<RoutingTasks> getRoutingTasks({@Query('routingId') String? routingId});

  @POST("rest/s1/growerp/100/RoutingTask")
  Future<RoutingTask> createRoutingTask({
    @Field() required RoutingTask routingTask,
  });

  @PATCH("rest/s1/growerp/100/RoutingTask")
  Future<RoutingTask> updateRoutingTask({
    @Field() required RoutingTask routingTask,
  });

  @DELETE("rest/s1/growerp/100/RoutingTask")
  Future<RoutingTask> deleteRoutingTask({
    @Field() required RoutingTask routingTask,
  });

  // liner
  @GET("rest/s1/growerp/100/LinerTypes")
  Future<LinerTypes> getLinerTypes({
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/LinerType")
  Future<LinerType> createLinerType({@Field() required LinerType linerType});

  @PATCH("rest/s1/growerp/100/LinerType")
  Future<LinerType> updateLinerType({@Field() required LinerType linerType});

  @DELETE("rest/s1/growerp/100/LinerType")
  Future<LinerType> deleteLinerType({@Field() required LinerType linerType});

  @GET("rest/s1/growerp/100/LinerPanels")
  Future<LinerPanels> getLinerPanels({
    @Query('workEffortId') String? workEffortId,
    @Query('salesOrderId') String? salesOrderId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/LinerPanel")
  Future<LinerPanel> createLinerPanel({
    @Field() required LinerPanel linerPanel,
  });

  @PATCH("rest/s1/growerp/100/LinerPanel")
  Future<LinerPanel> updateLinerPanel({
    @Field() required LinerPanel linerPanel,
  });

  @DELETE("rest/s1/growerp/100/LinerPanel")
  Future<LinerPanel> deleteLinerPanel({
    @Field() required LinerPanel linerPanel,
  });
}
