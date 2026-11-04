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

  @GET("rest/s1/growerp/100/Pos/Receipt")
  Future<PosSale> getPosReceipt({
    @Query('clientSaleId') required String clientSaleId,
  });
}
