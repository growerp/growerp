import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: null)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET("rest/s1/growerp/100/CheckEmail")
  Future<String> checkEmail(@Query('email') String email);

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
  Future<Authenticate> logout();

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
