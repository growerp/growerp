import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin WebsiteApi {
  // Website ======
  @GET("rest/s1/growerp/100/Website")
  Future<Website> getWebsite();

  @GET("rest/s1/growerp/100/WebsiteContent")
  Future<Content> getWebsiteContent({
    @Query('path') required String path,
    @Query('text') required String text,
  });

  @PATCH("rest/s1/growerp/100/Website")
  Future<Website> updateWebsite({@Field() required Website website});

  @POST("rest/s1/growerp/100/WebsiteContent")
  Future<Content> uploadWebsiteContent({@Field() required Content content});

  @POST("rest/s1/growerp/100/Obsidian")
  Future<Website> obsUpload({@Field() required Obsidian obsidian});

  @POST("rest/s1/growerp/100/ImportExport/website")
  Future<void> importWebsite(@Field() Website website);

  @GET("rest/s1/growerp/100/ImportExport/website")
  Future<Website> exportWebsite();

  // website lead-capture forms
  @GET("rest/s1/growerp/100/WebsiteForm")
  Future<WebsiteForms> getWebsiteForm({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('formId') String? formId,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/WebsiteForm")
  Future<WebsiteForm> createWebsiteForm({
    @Field() required WebsiteForm webForm,
  });

  @PATCH("rest/s1/growerp/100/WebsiteForm")
  Future<WebsiteForm> updateWebsiteForm({
    @Field() required WebsiteForm webForm,
  });

  @DELETE("rest/s1/growerp/100/WebsiteForm")
  Future<void> deleteWebsiteForm({@Field() required WebsiteForm webForm});
}
