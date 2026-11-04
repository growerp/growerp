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

  @GET("rest/s1/growerp/100/Pos/Receipt")
  Future<PosSale> getPosReceipt({
    @Query('clientSaleId') required String clientSaleId,
  });
}
