import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: "http://localhost:8080/")
@RestApi()
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
  Future<Authenticate> login(
      @Field() String username, @Field() password, @Field() classificationId);

  @POST("rest/s1/growerp/100/ImportExport")
  Future<String> import(@Body() Map<String, dynamic> entities);

  @GET("rest/s1/growerp/100/Category")
  Future<List<Category>> getCategory();

  @GET("rest/s1/growerp/100/AccountClass")
  Future<List<AccountClass>> getAccountClass();

  @GET("rest/s1/growerp/100/Product")
  Future<List<Product>> getProduct();
}
