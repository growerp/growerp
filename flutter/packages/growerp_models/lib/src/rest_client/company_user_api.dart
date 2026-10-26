import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin CompanyUserApi {
  // company
  @GET("rest/s1/growerp/100/CompanyFromHost")
  @Extra({'noApiKey': true})
  Future<Company> getCompanyFromHost(@Query('hostName') String? hostName);

  @GET("rest/s1/growerp/100/PublicCompany")
  @Extra({'noApiKey': true})
  Future<Company> getPublicCompany({
    @Query('companyPartyId') required String companyPartyId,
  });

  @GET("rest/s1/growerp/100/AcademyDirectory")
  @Extra({'noApiKey': true})
  Future<Companies> getAcademyDirectory({
    @Query('searchString') String? searchString,
  });

  // company
  @GET("rest/s1/growerp/100/Company")
  Future<Companies> getCompany({
    @Query('companyPartyId') String? companyPartyId,
    @Query('companyName') String? companyName,
    @Query('userPartyId') String? userPartyId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('searchString') String? searchString,
    @Query('isForDropDown') bool? isForDropDown,
  });

  @POST("rest/s1/growerp/100/Company")
  Future<Company> createCompany({@Field() required Company company});

  @PATCH("rest/s1/growerp/100/Company")
  Future<Company> updateCompany({@Field() required Company company});

  @DELETE("rest/s1/growerp/100/Company")
  Future<Company> deleteCompany({@Field() required String partyId});

  // party to replace company and user
  @GET("rest/s1/growerp/100/CompanyUser")
  Future<CompaniesUsers> getCompanyUser({
    @Query('role') Role? role,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('partyId') String? partyId,
  });

  @POST("rest/s1/growerp/100/ImportExport/companyUsers")
  Future<dynamic> importCompanyUsers(@Field() List<CompanyUser> companyUsers);

  @GET("rest/s1/growerp/100/ImportExport")
  Future<String> exportScreenCompanyUsers({
    @Query('entityName') String entityName = 'CompanyUser',
  });

  // user
  @GET("rest/s1/growerp/100/User")
  Future<Users> getUser({
    @Query('userPartyId') String? partyId,
    @Query('role') Role? role,
    @Query('customerStatus') String? customerStatus,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('search') String? searchString,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('loginOnly') bool? loginOnly,
  });

  @POST("rest/s1/growerp/100/User")
  Future<User> createUser({
    @Field() required User user,
    @Field() String? password,
  });

  @PATCH("rest/s1/growerp/100/User")
  Future<User> updateUser({@Field() required User user});

  @DELETE("rest/s1/growerp/100/User")
  Future<User> deleteUser({
    @Field() required String partyId,
    @Field() required bool deleteCompanyToo,
  });

  /// Marks the current app as used by the logged-in user so one-time
  /// post-login flows (welcome/assessment) appear only on the first login.
  @POST("rest/s1/growerp/100/AppUsed")
  Future<void> registerAppUsed({@Field() required String applicationId});

  // payment gateway actions
  @POST("rest/s1/growerp/100/GatewayPayment")
  Future<FinDoc> authorizeGatewayPayment({@Field() required String paymentId});
  @PATCH("rest/s1/growerp/100/GatewayPayment")
  Future<FinDoc> captureGatewayPayment({@Field() required String paymentId});
  @DELETE("rest/s1/growerp/100/GatewayPayment")
  Future<FinDoc> releaseGatewayPayment({@Field() required String paymentId});
}
