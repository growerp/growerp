import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: "http://localhost:8080/")
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST("rest/s1/growerp/100/UserAndCompany")
  @FormUrlEncoded()
  Future<Authenticate> register(
    @Field() String emailAddress,
    @Field() String companyEmailAddress,
    @Field() String newPassword,
    @Field() String firstName,
    @Field() String lastName,
    @Field() String companyName,
    @Field() String currencyId,
    @Field() String classificationId,
    @Field() bool demoData,
  );

  @GET("rest/s1/growerp/100/CheckEmail")
  Future<String> checkEmail(@Query('email') String email);

  @POST("rest/s1/growerp/100/Login")
  @FormUrlEncoded()
  Future<Authenticate> login(
      @Field() String username, @Field() password, @Field() classificationId);

  @POST("rest/s1/growerp/100/ImportExport/glAccounts")
  Future<void> importGlAccounts(@Header('api_key') String apiKey,
      @Field() List<GlAccount> glAccounts, @Field() String classificationId);

  @POST("rest/s1/growerp/100/ImportExport/companies")
  Future<void> importCompanies(@Header('api_key') String apiKey,
      @Field() List<Company> companies, @Field() String classificationId);

  @POST("rest/s1/growerp/100/ImportExport/users")
  Future<void> importUsers(@Header('api_key') String apiKey,
      @Field() List<User> users, @Field() String classificationId);

  @POST("rest/s1/growerp/100/ImportExport/products")
  Future<void> importProducts(@Header('api_key') String apiKey,
      @Field() List<Product> products, @Field() String classificationId);

  @POST("rest/s1/growerp/100/ImportExport/categories")
  Future<void> importCategories(@Header('api_key') String apiKey,
      @Field() List<Category> categories, @Field() String classificationId);

  @GET("rest/s1/growerp/100/GlAccount")
  Future<GlAccounts> getGlAccount(
      @Header('api_key') String apiKey, @Query('limit') String limit);

  @GET("rest/s1/growerp/100/Categories")
  Future<Categories> getCategories(
      @Header('api_key') String apiKey, @Query('limit') String limit);

  @GET("rest/s1/growerp/100/Products")
  Future<Products> getProducts(
    @Header('api_key') String apiKey,
    @Query('limit') String limit,
  );

  @GET("rest/s1/growerp/100/User")
  Future<Users> getUsers(
      @Header('api_key') String apiKey, @Query('limit') String limit);

  @GET("rest/s1/growerp/100/Company")
  Future<Companies> getCompanies(
      @Header('api_key') String apiKey, @Query('limit') String limit);
}
