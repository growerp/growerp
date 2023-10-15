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

  @POST("rest/s1/growerp/100/Login")
  @FormUrlEncoded()
  Future<Authenticate> login(@Field() String username, @Field() password);

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> import(@Field() Map<String, dynamic> entities);

  @GET("rest/s1/growerp/100/GlAccount")
  Future<List<GlAccount>> getGlAccount(@Query('limit') String limit);

  @GET("rest/s1/growerp/100/Categories")
  Future<List<Category>> getCategories(@Query('limit') String limit);

  @GET("rest/s1/growerp/100/Products")
  Future<List<Product>> getProducts(@Query('limit') String limit);

  @GET("rest/s1/growerp/100/User")
  Future<List<User>> getUsers(@Query('limit') String limit);

  @GET("rest/s1/growerp/100/Company")
  Future<List<Company>> getCompanies(@Query('limit') String limit);
}
