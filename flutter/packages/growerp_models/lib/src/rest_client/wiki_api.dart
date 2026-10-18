import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin WikiApi {
  // Wiki spaces + pages (OKF knowledge bundle browse/edit)
  @GET("rest/s1/growerp/100/WikiSpaces")
  Future<WikiSpaces> getWikiSpaces({
    @Query('searchString') String? searchString,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/WikiPages")
  Future<WikiPages> getWikiPages({
    @Query('wikiSpaceId') required String wikiSpaceId,
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/WikiPage")
  Future<WikiPage> getWikiPage({
    @Query('wikiSpaceId') required String wikiSpaceId,
    @Query('pagePath') String? pagePath,
  });

  @POST("rest/s1/growerp/100/WikiPage")
  Future<WikiPage> updateWikiPage({
    @Field() required String wikiSpaceId,
    @Field() required String pagePath,
    @Field() String? pageText,
  });

  @DELETE("rest/s1/growerp/100/WikiPage")
  Future<void> deleteWikiPage({
    @Query('wikiPageId') required String wikiPageId,
  });
}
