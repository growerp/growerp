import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin AuthApi {
  @GET("rest/s1/growerp/100/CheckEmail")
  @Extra({'noApiKey': true})
  Future<Map<String, bool>> checkEmail({@Query('email') required String email});

  @POST("rest/s1/growerp/100/Register")
  @Extra({'noApiKey': true})
  @FormUrlEncoded()
  Future<Authenticate> register({
    @Field() required String applicationId,
    @Field() required String firstName,
    @Field() required String lastName,
    @Field() required String email,
    @Field() String? companyPartyId, // required for other than admin
    @Field() String? newPassword,
    @Field('userGroupId') UserGroup? userGroup, // if admin also company
    @Field() String? timeZoneOffset,
    @Field() String? locale,
  });

  @POST("rest/s1/growerp/100/Login")
  @Extra({'noApiKey': true})
  @FormUrlEncoded()
  Future<Authenticate> login({
    @Field() required String username,
    @Field() required String password,
    @Field() String? creditCardNumber,
    @Field() String? creditCardType,
    @Field() String? nameOnCard,
    @Field() String? expireMonth,
    @Field() String? expireYear,
    @Field() String? cVC,
    @Field() String? plan,
    @Field() String? companyName,
    @Field() String? currencyId,
    @Field() int? fiscalYearStartMonth,
    @Field() bool? demoData,
    @Field() required String applicationId,
    @Field() String? timeZoneOffset,
    @Field() String? locale,
    @Field() int? testDaysOffset,
  });

  @POST("rest/s1/growerp/100/Logout")
  Future<String> logout();

  @POST("rest/s1/growerp/100/ResetPassword")
  @Extra({'noApiKey': true})
  Future<String> resetPassword({@Field() required String username});

  @GET("rest/s1/growerp/100/TempResetPassword")
  @Extra({'noApiKey': true})
  Future<String> getTempResetPassword({
    @Query('username') required String username,
  });

  @POST("rest/s1/growerp/100/Password")
  @Extra({'noApiKey': true})
  Future<Authenticate> updatePassword({
    @Field() required String username,
    @Field() required String oldPassword,
    @Field() required String newPassword,
    @Field() required String applicationId,
  });

  @GET("rest/s1/growerp/100/Companies")
  @Extra({'noApiKey': true})
  Future<Companies> getCompanies({
    @Query('mainCompanies') bool? mainCompanies,
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/RestRequest")
  Future<RestRequests> getRestRequest({
    @Query('hitId') String? hitId,
    @Query('userId') String? userId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('startDateTime') String? startDateTime,
    @Query('endDateTime') String? endDateTime,
    @Query('search') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/RestUsageStatistics")
  Future<RestUsageStatistics> getRestUsageStatistics({
    @Query('startDateTime') String? startDateTime,
    @Query('endDateTime') String? endDateTime,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('maxUsers') int? maxUsers,
  });

  @GET("rest/s1/growerp/100/SignupStatistics")
  Future<SignupStatistics> getSignupStatistics({
    @Query('startDateTime') String? startDateTime,
    @Query('endDateTime') String? endDateTime,
    @Query('applicationId') String? applicationId,
    @Query('search') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/SupportDashboard")
  Future<SupportDashboard> getSupportDashboard({
    @Query('periodDays') int? periodDays,
  });

  @GET("rest/s1/growerp/100/InfraMetrics")
  Future<InfraMetrics> getInfraMetrics();

  @GET("rest/s1/growerp/100/Authenticate")
  Future<Authenticate> getAuthenticate({
    @Query('applicationId') required String applicationId,
  });

  // backend application url override
  @GET("rest/s1/growerp/100/Application")
  Future<Applications> getApplication();

  // applications
  @POST("rest/s1/growerp/100/Application")
  Future<Application> createApplication(@Field() Application application);

  @DELETE("rest/s1/growerp/100/Application")
  Future<Application> deleteApplication(@Field() Application application);
}
