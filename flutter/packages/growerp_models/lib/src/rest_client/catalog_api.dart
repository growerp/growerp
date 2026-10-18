import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin CatalogApi {
  // catalog
  // asset
  @GET("rest/s1/growerp/100/Asset")
  Future<Assets> getAsset({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('assetClassId') String? assetClassId,
    @Query('assetId') String? assetId,
    @Query('productId') String? productId,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Asset")
  Future<Asset> createAsset({
    @Field() required Asset asset,
    @Field() required String applicationId,
  });

  @PATCH("rest/s1/growerp/100/Asset")
  Future<Asset> updateAsset({
    @Field() required Asset asset,
    @Field() required String applicationId,
  });

  // categories
  @GET("rest/s1/growerp/100/Categories")
  Future<Categories> getCategory({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('applicationId') String? applicationId,
  });

  @POST("rest/s1/growerp/100/Category")
  Future<Category> createCategory({
    @Field() required Category category,
    @Field() required String applicationId,
  });

  @PATCH("rest/s1/growerp/100/Category")
  Future<Category> updateCategory({
    @Field() required Category category,
    @Field() required String applicationId,
  });

  @DELETE("rest/s1/growerp/100/Category")
  Future<Category> deleteCategory({@Field() required Category category});

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> importScreenCategories({
    @Field() required List categories,
    @Field() required String applicationId,
  });

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportScreenCategories({
    @Query('entityName') String entityName = 'Category',
    @Query('applicationId') String? applicationId,
  });

  /// The GROWERP subscription plans with their current price:
  /// {plans: [{productId, productName, description, price, currencyUomId}]}
  @GET("rest/s1/growerp/100/SubscriptionPlans")
  Future<dynamic> getSubscriptionPlans();

  // products
  @GET("rest/s1/growerp/100/Products")
  Future<Products> getProduct({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('applicationId') String? applicationId,
    @Query('categoryId') String? categoryId,
    @Query('productId') String? productId,
    @Query('productTypeId') String? productTypeId,
    @Query('assetClassId') String? assetClassId,
  });

  @POST("rest/s1/growerp/100/Product")
  Future<Product> createProduct({
    @Field() required Product product,
    @Field() required String applicationId,
  });

  @PATCH("rest/s1/growerp/100/Product")
  Future<Product> updateProduct({
    @Field() required Product product,
    @Field() required String applicationId,
  });

  @DELETE("rest/s1/growerp/100/Product")
  Future<Product> deleteProduct({@Field() required Product product});

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> importScreenProducts({
    @Field() required List<Product> products,
    @Field() required String applicationId,
  });

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportScreenProducts({
    @Query('entityName') String entityName = 'Product',
    @Query('applicationId') required String applicationId,
  });

  // dayly rental
  @GET("rest/s1/growerp/100/DailyRentalOccupancy")
  Future<ProductRentalDates> getDailyRentalOccupancy({
    @Query('productId') String? productId,
  });
}
