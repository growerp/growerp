import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: null)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET("rest/s1/growerp/100/CheckEmail")
  Future<Map<String, bool>> checkEmail({@Query('email') required String email});

  @POST("rest/s1/growerp/100/UserAndCompany")
  @FormUrlEncoded()
  Future<Authenticate> register({
    @Field() required String emailAddress,
    @Field() required String companyEmailAddress,
    @Field() required String firstName,
    @Field() required String lastName,
    @Field() required String companyName,
    @Field() required String currencyId,
    @Field() required bool demoData,
    @Field() required String classificationId,
    @Field() String? newPassword,
  });

  @POST("rest/s1/growerp/100/Login")
  @FormUrlEncoded()
  Future<Authenticate> login({
    @Field() required String username,
    @Field() required String password,
    @Field() required String classificationId,
  });

  @POST("rest/s1/growerp/100/Logout")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<String> logout();

  @POST("rest/s1/growerp/100/ResetPassword")
  Future<String> resetPassword({@Field() required String username});

  @POST("rest/s1/growerp/100/Password")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Authenticate> updatePassword({
    @Field() required String username,
    @Field() required String oldPassword,
    @Field() required String newPassword,
  });

  @GET("rest/s1/growerp/100/Companies")
  Future<Companies> getCompanies({
    @Query('mainCompanies') bool? mainCompanies,
    @Query('searchString') String? searchString,
    @Query('filter') String? filter,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/Authenticate")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Authenticate> getAuthenticate(
      {@Query('classificationId') required String classificationId});

  @GET("rest/s1/growerp/100/Company")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Companies> getCompany({
    @Query('companyPartyId') String? companyPartyId,
    @Query('companyName') String? companyName,
    @Query('userpartyId') String? userpartyId,
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('filter') String? filter,
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('searchString') Role? searchString,
  });

  // Website ======
  @GET("rest/s1/growerp/100/Website")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Website> getWebsite();

  @GET("rest/s1/growerp/100/WebsiteContent")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Content> getWebsiteContent(
      {@Query('content') required Content content});

  @PATCH("rest/s1/growerp/100/Website")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Website> updateWebsite({@Field() required Website website});

  @POST("rest/s1/growerp/100/WebsiteContent")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Content> uploadWebsiteContent({@Field() required Content content});

  @POST("rest/s1/growerp/100/Obsidian")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Website> obsUpload({@Field() required Obsidian obsidian});

  @POST("rest/s1/growerp/100/ImportExport/website")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<void> importWebsite(@Field() Website website);

  @GET("rest/s1/growerp/100/ImportExport/website")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Website> exportWebsite();

  // catalog
  // asset
  @GET("rest/s1/growerp/100/Asset")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Assets> getAsset(
      {@Query('start') int? start,
      @Query('limit') int? limit,
      @Query('companyPartyId') String? companyPartyId,
      @Query('assetClassId') String? assetClassId,
      @Query('assetId') String? assetId,
      @Query('productId') String? productId,
      @Query('filter') String? filter,
      @Query('search') String? search});

  @POST("rest/s1/growerp/100/Asset")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Asset> createAsset(
      {@Field() required Asset asset,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Asset")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Asset> updateAsset(
      {@Field() required Asset asset,
      @Field() required String classificationId});

  // categories
  @GET("rest/s1/growerp/100/Categories")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Categories> getCategory({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('filter') String? filter,
    @Query('search') String? searchString,
    @Query('classificationId') String? classificationId,
  });

  @POST("rest/s1/growerp/100/Category")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Category> createCategory(
      {@Field() required Category category,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Category")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Category> updateCategory(
      {@Field() required Category category,
      @Field() required String classificationId});

  @DELETE("rest/s1/growerp/100/Category")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Category> deleteCategory({@Field() required Category category});

  @POST("rest/s1/growerp/100/ImportExport")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<String> importScreenCategories(
      {@Field() required List categories,
      @Field() required String classificationId});

  @GET("rest/s1/growerp/100/ImportExport")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<String> exportScreenCategories({
    @Query('entityName') String entityName = 'Category',
    @Query('classificationId') String? classificationId,
  });

  // products
  @GET("rest/s1/growerp/100/Products")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Products> getProduct({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('companyPartyId') String? companyPartyId,
    @Query('filter') String? filter,
    @Query('search') String? searchString,
    @Query('classificationId') String? classificationId,
    @Query('categoryId') String? categoryId,
    @Query('productId') String? productId,
    @Query('productTypeId') String? productTypeId,
    @Query('assetClassId') String? assetClassId,
  });

  @POST("rest/s1/growerp/100/Product")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Product> createProduct(
      {@Field() required Product product,
      @Field() required String classificationId});

  @PATCH("rest/s1/growerp/100/Product")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Product> updateProduct(
      {@Field() required Product product,
      @Field() required String classificationId});

  @DELETE("rest/s1/growerp/100/Product")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Product> deleteProduct({@Field() required Product product});

  @POST("rest/s1/growerp/100/ImportExport")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<String> importScreenProducts(
      {@Field() required List products,
      @Field() required String classificationId});

  @GET("rest/s1/growerp/100/ImportExport")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<String> exportScreenProducts({
    @Query('entityName') String entityName = 'Product',
    @Query('classificationId') required String classificationId,
  });

  // rental
  @GET("rest/s1/growerp/100/RentalOccupancy")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<RentalFullDates> getRentalOccupancy({
    @Query('productId') required String productId,
  });
  @GET("rest/s1/growerp/100/RentalOccupancy")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Products> getRentalAllOccupancy();

  // import / export ========
  @POST("rest/s1/growerp/100/ImportExport/glAccounts")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<void> importGlAccounts(@Field() List<GlAccount> glAccounts);

  @POST("rest/s1/growerp/100/ImportExport/companies")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<void> importCompanies(@Field() List<Company> companies);

  @POST("rest/s1/growerp/100/ImportExport/users")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<void> importUsers(@Field() List<User> users);

  @POST("rest/s1/growerp/100/ImportExport/products")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<void> importProducts(
      @Field() List<Product> products, @Field() String classificationId);

  @POST("rest/s1/growerp/100/ImportExport/categories")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<void> importCategories(@Field() List<Category> categories);

  @GET("rest/s1/growerp/100/GlAccount")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<GlAccounts> getGlAccount({@Query('limit') int? limit});

  @GET("rest/s1/growerp/100/Categories")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Categories> getCategories({@Query('limit') int? limit});

  @GET("rest/s1/growerp/100/Products")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Products> getProducts({
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/User")
  @Headers(<String, dynamic>{'requireApiKey': true})
  Future<Users> getUsers(@Query('limit') String limit);
}
