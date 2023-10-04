import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';

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
  Future<String> import(@Field() Map<String, dynamic> entities);

  @GET("rest/s1/growerp/100/GlAccount")
  Future<GlAccountList> getGlAccount(@Query('limit') String limit);
}

GlAccountList deserializeGlAccountList(Map<String, dynamic> json) =>
    GlAccountList.fromJson(json);

@JsonSerializable()
class GlAccountList {
  const GlAccountList({required this.glAccountList});

  final List<GlAccount> glAccountList;

  factory GlAccountList.fromJson(Map<String, dynamic> json) =>
      _$GlAccountListFromJson(json);

  List<GlAccount> toList() => this.glAccountList.toList();
}
