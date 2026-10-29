import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin FinDocApi {
  // FINDOC
  @GET("rest/s1/growerp/100/FinDoc")
  Future<FinDocs> getFinDoc({
    @Query('finDocId') String? finDocId,
    @Query('pseudoId') String? pseudoId,
    @Query('sales') bool? sales,
    @Query('docType') FinDocType? docType,
    @Query('companyPartyId') String? companyPartyId,
    @Query('search') String? searchString,
    @Query('journalId') String? journalId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('my') bool? my,
    @Query('status') FinDocStatusVal? status,
  });

  @POST("rest/s1/growerp/100/FinDoc")
  Future<FinDoc> createFinDoc({@Field() required FinDoc finDoc});

  @PATCH("rest/s1/growerp/100/FinDoc")
  Future<FinDoc> updateFinDoc({@Field() required FinDoc finDoc});

  @PATCH("rest/s1/growerp/100/FinDocShipment")
  Future<FinDoc> receiveShipment({@Field() required FinDoc finDoc});

  /// Email a client-rendered invoice/order PDF to its counterparty. [pdfBase64]
  /// is the same bytes PdfFormats.finDocPdf already renders for the print
  /// preview; [toEmail] overrides the document's contact email.
  @POST("rest/s1/growerp/100/FinDocEmail")
  Future<void> sendFinDocEmail({
    @Field() required String finDocId,
    @Field() required String pdfBase64,
    @Field() String? toEmail,
  });

  /// Read a supplier invoice image ([imageData] base64) with the company's AI
  /// model; returns a new purchase invoice to review, not saved yet.
  @POST("rest/s1/growerp/100/FinDocFromImage")
  Future<FinDoc> getFinDocFromImage({
    @Field() required String imageData,
    @Field() required String mimeType,
  });

  @GET("rest/s1/growerp/100/ItemType")
  Future<ItemTypes> getItemTypes({@Query('sales') bool? sales});

  @PATCH("rest/s1/growerp/100/ItemType")
  Future<ItemType> updateItemType({
    @Field() required ItemType itemType,
    @Field() bool? update,
    @Field() bool? delete,
  });

  @GET("rest/s1/growerp/100/PaymentType")
  Future<PaymentTypes> getPaymentTypes({@Query('sales') bool? sales});

  @PATCH("rest/s1/growerp/100/PaymentType")
  Future<PaymentType> updatePaymentType({
    @Field() required PaymentType paymentType,
    @Field() bool? update,
    @Field() bool? delete,
  });

  @POST("rest/s1/growerp/100/ImportExport/finDocs")
  Future<void> importFinDoc(@Field() List<FinDoc> finDocs);

  @POST("rest/s1/growerp/100/ImportExport/finDocItems")
  Future<void> importFinDocItem(
    @Field() List<FinDocItem> finDocItems,
    @Field() String applicationId,
  );

  // finalize import
  @POST("rest/s1/growerp/100/ImportExport/finalizeImport")
  Future<Map<String, String>> finalizeImport({
    @Field() required int start,
    @Field() required int limit,
    @Field() required String part, //
    // closePeriod, approveInvoices, completePayments,
    // completeInvoicesOrders, receiveShipments, sendShipments
  });
}
