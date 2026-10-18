import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin CrmApi {
  // opportunities
  @GET("rest/s1/growerp/100/Opportunity")
  Future<Opportunities> getOpportunity({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('opportunityId') String? opportunityId,
    @Query('search') String? searchString,
  });

  @GET("rest/s1/growerp/100/Opportunity/Summary")
  Future<OpportunitySummary> getOpportunitySummary();

  @GET("rest/s1/growerp/100/Opportunity/WeekStats")
  Future<OpportunityWeekStats> getOpportunityWeekStats({
    @Query('weeks') int? weeks,
  });

  // subscriptions
  @GET("rest/s1/growerp/100/Subscription")
  Future<Subscriptions> getSubscription({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('subscriptionId') String? subscriptionId,
    @Query('growerp')
    bool? growerp, // if true, only owner GROWERP subscriptions
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/Subscription")
  Future<Subscription> createSubscription({
    @Field() required Subscription subscription,
  });

  @PATCH("rest/s1/growerp/100/Subscription")
  Future<Subscription> updateSubscription({
    @Field() required Subscription subscription,
  });

  @DELETE("rest/s1/growerp/100/Subscription")
  Future<Subscription> deleteSubscription({
    @Field() required Subscription subscription,
  });

  @POST("rest/s1/mcp/ProcessInvoiceImage")
  @FormUrlEncoded()
  Future<String> processInvoiceImage({
    @Field() required String imageData,
    @Field() required String prompt,
    @Field() required String mimeType,
  });

  @POST("rest/s1/mcp/CreateInvoiceFromData")
  Future<String> createInvoiceFromData({
    @Field() required Map<String, dynamic> invoiceData,
  });
}
