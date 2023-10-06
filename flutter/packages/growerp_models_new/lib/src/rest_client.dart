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

  @GET("rest/s1/growerp/100/Categories")
  Future<Categories> getCategories(@Query('limit') String limit);

  @GET("rest/s1/growerp/100/Products")
  Future<Products> getProducts(@Query('limit') String limit);

  @GET("rest/s1/growerp/100/User")
  Future<Users> getUsers(@Query('limit') String limit);

  @GET("rest/s1/growerp/100/Company")
  Future<Companies> getCompanies(@Query('limit') String limit);
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

Categories deserializeCategories(Map<String, dynamic> json) =>
    Categories.fromJson(json);

@JsonSerializable()
class Categories {
  const Categories({required this.categories});

  final List<Category> categories;

  factory Categories.fromJson(Map<String, dynamic> json) =>
      _$CategoriesFromJson(json);

  List<Category> toList() => this.categories.toList();
}

Products deserializeProducts(Map<String, dynamic> json) =>
    Products.fromJson(json);

@JsonSerializable()
class Products {
  const Products({required this.products});

  final List<Product> products;

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);

  List<Product> toList() => this.products.toList();
}

Companies deserializeCompanies(Map<String, dynamic> json) =>
    Companies.fromJson(json);

@JsonSerializable()
class Companies {
  const Companies({required this.companies});

  final List<Company> companies;

  factory Companies.fromJson(Map<String, dynamic> json) =>
      _$CompaniesFromJson(json);

  List<Company> toList() => this.companies.toList();
}

Users deserializeUsers(Map<String, dynamic> json) => Users.fromJson(json);

@JsonSerializable()
class Users {
  const Users({required this.users});

  final List<User> users;

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);

  List<User> toList() => this.users.toList();
}
