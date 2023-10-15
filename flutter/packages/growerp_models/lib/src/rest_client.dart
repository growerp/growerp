import 'package:dio/dio.dart' hide Headers;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: "http://localhost:8080/")
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

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
    @Field() String? classificationId,
    @Field() String? newPassword,
  });

  @GET("rest/s1/growerp/100/CheckEmail")
  Future<String> checkEmail(@Query('email') String email);

  @GET("rest/s1/growerp/100/Company")
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

  @GET("rest/s1/growerp/100/Companies")
  Future<Companies> getCompanies({
    @Query('companyPartyId') String? companyPartyId,
  });

  @GET("rest/s1/growerp/100/Authenticate")
  Future<Authenticate> getAuthenticate();

  @POST("rest/s1/growerp/100/Login")
  @FormUrlEncoded()
  Future<Authenticate> login(@Field() String username, @Field() String password,
      {@Field() String classificationId = 'AppAdmin'});

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
  Future<void> importProducts(@Field() List<Product> products);

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
