import 'package:decimal/decimal.dart';
import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin PosApi {
  @GET("rest/s1/growerp/100/Pos/Catalog")
  Future<PosCatalog> getPosCatalog();

  @GET("rest/s1/growerp/100/Pos/Barcode")
  Future<PosCatalogItem> getPosProductByBarcode({
    @Query('barcode') required String barcode,
  });

  @POST("rest/s1/growerp/100/Pos/Quote")
  Future<PosQuote> getPosQuote({@Field() required List<PosLine> lines});

  @POST("rest/s1/growerp/100/Pos/Sale")
  Future<PosSale> createPosSale({
    @Field() required String clientSaleId,
    @Field() String? terminalName,
    @Field() required List<PosLine> lines,
    @Field() required List<PosTender> tenders,
  });

  @GET("rest/s1/growerp/100/Pos/SaleLookup")
  Future<PosSale> getPosSaleLookup({@Query('search') required String search});

  @POST("rest/s1/growerp/100/Pos/Refund")
  Future<PosRefund> createPosRefund({
    @Field() required String clientRefundId,
    @Field() required String clientSaleId,
    @Field() required List<PosRefundLine> lines,
    @Field() required bool restock,
    @Field() String? terminalName,
  });

  /// a closed till gives a shift without an id
  @GET("rest/s1/growerp/100/Pos/Shift")
  Future<PosShift> getPosShift({
    @Query('terminalName') required String terminalName,
  });

  @POST("rest/s1/growerp/100/Pos/Shift")
  Future<PosShift> openPosShift({
    @Field() required String terminalName,
    @Field() required Decimal openingFloat,
  });

  @GET("rest/s1/growerp/100/Pos/Shifts")
  Future<PosShifts> getPosShifts({
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Pos/ShiftClose")
  Future<PosZReport> closePosShift({
    @Field() required String shiftId,
    @Field() required Decimal countedCash,
  });

  @POST("rest/s1/growerp/100/Pos/CashMovement")
  Future<void> createPosCashMovement({
    @Field() required String shiftId,
    @Field() required Decimal amount,
    @Field() String? reason,
  });

  @GET("rest/s1/growerp/100/Pos/ZReport")
  Future<PosZReport> getPosZReport({@Query('shiftId') required String shiftId});

  @GET("rest/s1/growerp/100/Pos/FloorPlan")
  Future<PosTables> getPosFloorPlan();

  @POST("rest/s1/growerp/100/Pos/Table")
  Future<PosTable> createPosTable({@Field() required PosTable table});

  @PATCH("rest/s1/growerp/100/Pos/Table")
  Future<void> updatePosTable({@Field() required PosTable table});

  @DELETE("rest/s1/growerp/100/Pos/Table")
  Future<void> deletePosTable({@Field() required String assetId});

  @GET("rest/s1/growerp/100/Pos/Tab")
  Future<PosTab> getPosTab({@Query('tabId') required String tabId});

  @POST("rest/s1/growerp/100/Pos/Tab")
  Future<PosTab> openPosTab({
    @Field() String? tableAssetId,
    @Field() int? guestCount,
  });

  @DELETE("rest/s1/growerp/100/Pos/Tab")
  Future<void> cancelPosTab({@Field() required String tabId});

  @POST("rest/s1/growerp/100/Pos/TabMove")
  Future<PosTab> movePosTab({
    @Field() required String tabId,
    @Field() required String tableAssetId,
  });

  @POST("rest/s1/growerp/100/Pos/TabLine")
  Future<PosTab> addPosTabLine({
    @Field() required String tabId,
    @Field() required String productId,
    @Field() required Decimal quantity,
    @Field() List<String>? modifierIds,
    @Field() String? note,
    @Field() int? seatNo,
  });

  @PATCH("rest/s1/growerp/100/Pos/TabLine")
  Future<PosTab> updatePosTabLine({
    @Field() required String tabId,
    @Field() required String orderItemSeqId,
    @Field() Decimal? quantity,
    @Field() String? note,
  });

  @DELETE("rest/s1/growerp/100/Pos/TabLine")
  Future<PosTab> voidPosTabLine({
    @Field() required String tabId,
    @Field() required String orderItemSeqId,
    @Field() String? reason,
  });

  @POST("rest/s1/growerp/100/Pos/TabSend")
  Future<PosTab> sendPosTab({@Field() required String tabId});

  @POST("rest/s1/growerp/100/Pos/TabSplit")
  Future<PosShares> splitPosTab({
    @Field() required String tabId,
    @Field() int? ways,
    @Field() List<PosSplitAssignment>? assignments,
  });

  @POST("rest/s1/growerp/100/Pos/TabSettle")
  Future<PosSale> settlePosTab({
    @Field() required String clientSaleId,
    @Field() required String tabId,
    @Field() required String terminalName,
    @Field() required List<PosTender> tenders,
  });

  @GET("rest/s1/growerp/100/Pos/Kitchen")
  Future<PosTickets> getPosKitchen();

  @PATCH("rest/s1/growerp/100/Pos/Kitchen")
  Future<void> updatePosKitchenLine({
    @Field() required String orderId,
    @Field() required String orderItemSeqId,
    @Field() required String kitchenStatus,
  });

  @GET("rest/s1/growerp/100/Pos/ModifierGroup")
  Future<PosModifierGroups> getPosModifierGroups();

  @POST("rest/s1/growerp/100/Pos/ModifierGroup")
  Future<PosModifierGroup> storePosModifierGroup({
    @Field() required PosModifierGroup group,
  });

  @DELETE("rest/s1/growerp/100/Pos/ModifierGroup")
  Future<void> deletePosModifierGroup({@Field() required String groupId});

  @GET("rest/s1/growerp/100/Pos/Receipt")
  Future<PosSale> getPosReceipt({
    @Query('clientSaleId') required String clientSaleId,
  });
}
