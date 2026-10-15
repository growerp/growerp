import 'package:retrofit/retrofit.dart';

import '../models/models.dart';
import '../models/platform_configurations_model.dart';
import '../models/campaign_progress_model.dart';

mixin OutreachApi {
  // ========================================================
  // OUTREACH CAMPAIGN ENDPOINTS
  // ========================================================

  // Outreach Campaign endpoints
  @GET("rest/s1/growerp/100/OutreachCampaigns")
  Future<OutreachCampaigns> listOutreachCampaigns({
    @Query('status') String? status,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @GET("rest/s1/growerp/100/OutreachCampaign")
  Future<OutreachCampaigns> getOutreachCampaigns({
    @Query('marketingCampaignId') String? marketingCampaignId,
    @Query('pseudoId') String? pseudoId,
    @Query('statusId') String? statusId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/OutreachCampaign")
  Future<CampaignDetail> getOutreachCampaignDetail({
    @Query('marketingCampaignId') String? marketingCampaignId,
    @Query('pseudoId') String? pseudoId,
  });

  @POST("rest/s1/growerp/100/OutreachCampaign")
  Future<OutreachCampaign> createOutreachCampaign({
    @Field() required Map<String, dynamic> campaign,
  });

  @PATCH("rest/s1/growerp/100/OutreachCampaign")
  Future<OutreachCampaign> updateOutreachCampaign({
    @Field() required Map<String, dynamic> campaign,
  });

  @DELETE("rest/s1/growerp/100/OutreachCampaign")
  Future<void> deleteOutreachCampaign({
    @Field() required String marketingCampaignId,
  });

  @POST("rest/s1/growerp/100/OutreachCampaign/generateWithAI")
  Future<OutreachCampaign> generateOutreachCampaignWithAI({
    @Field() required String campaignGoal,
    @Field() String? targetAudience,
    @Field() String? platforms,
  });

  // Campaign Automation endpoints
  @POST("rest/s1/growerp/100/OutreachCampaign/start")
  Future<dynamic> startCampaignAutomation({
    @Field() required String marketingCampaignId,
  });

  @POST("rest/s1/growerp/100/OutreachCampaign/pause")
  Future<dynamic> pauseCampaignAutomation({
    @Field() required String marketingCampaignId,
  });

  /// Drain the campaign's PENDING OutreachMessages server-side, per platform,
  /// up to dailyLimitPerPlatform. EMAIL is sent through the company's own SMTP
  /// server, so no browser automation is involved.
  @POST("rest/s1/growerp/100/OutreachCampaign/process")
  Future<dynamic> processCampaignAutomation({
    @Field() required String marketingCampaignId,
  });

  @GET("rest/s1/growerp/100/OutreachMessage")
  Future<OutreachMessages> listOutreachMessages({
    @Query("marketingCampaignId") String? marketingCampaignId,
    @Query("status") String? status,
    @Query("start") int? start,
    @Query("limit") int? limit,
    @Query("search") String? search,
  });

  @DELETE("rest/s1/growerp/100/OutreachMessage")
  Future<void> deleteOutreachMessage({@Field() required String messageId});

  /// Requeue failed messages: status back to PENDING with the attempt counter
  /// reset. Pass messageId for one message, marketingCampaignId for all failed
  /// messages of a campaign. Returns retriedCount.
  @POST("rest/s1/growerp/100/OutreachMessage/retry")
  Future<dynamic> retryOutreachMessages({
    @Field() String? messageId,
    @Field() String? marketingCampaignId,
  });

  @GET("rest/s1/growerp/100/OutreachCampaign/progress")
  Future<CampaignProgress> getCampaignProgress({
    @Query('marketingCampaignId') required String marketingCampaignId,
  });

  // Outreach Message endpoints
  @POST("rest/s1/growerp/100/OutreachMessage")
  Future<OutreachMessage> createOutreachMessage({
    @Field() required String marketingCampaignId,
    @Field() required String platform,
    @Field() String? recipientName,
    @Field() String? recipientProfileUrl,
    @Field() String? recipientHandle,
    @Field() String? recipientEmail,
    @Field() String? recipientCompany,
    @Field() String? recipientTitle,
    @Field() required String messageContent,

    /// Subject override for EMAIL; the campaign subject is used when empty
    @Field() String? emailSubject,
    @Field() String? status,
  });

  @PATCH("rest/s1/growerp/100/OutreachMessage")
  Future<OutreachMessage> updateOutreachMessageStatus({
    @Field() required String messageId,
    @Field() required String status,
    @Field() int? responseDate,
    @Field() String? errorMessage,

    /// Set when status == 'CONVERTED'; the partyId of the newly created
    /// User(role: lead) that this cold prospect was promoted to.
    @Field() String? convertedPartyId,
  });

  /// Bulk-import recipients (e.g. a LinkedIn CSV) as PENDING OutreachMessages for
  /// a campaign. messageContent is auto-personalized server-side from the
  /// campaign's messageTemplate using {name}/{company}/{title} substitution.
  @POST("rest/s1/growerp/100/OutreachRecipients")
  Future<dynamic> importOutreachRecipients({
    @Field() String? marketingCampaignId,
    @Field() String? pseudoId,
    @Field() String? defaultPlatform,
    @Field() required List<Map<String, dynamic>> recipients,
  });

  /// Persist an edited/AI-polished PENDING message body.
  @PATCH("rest/s1/growerp/100/OutreachMessageContent")
  Future<dynamic> updateOutreachMessageContent({
    @Field() required String messageId,
    @Field() required String messageContent,

    /// Subject override for EMAIL; '' falls back to the campaign subject
    @Field() String? emailSubject,
  });

  /// AI-polish the tone of an already-personalized message draft (does not persist).
  @POST("rest/s1/growerp/100/PolishOutreachMessage")
  Future<Map<String, String>> polishOutreachMessage({
    @Field() required String draftMessage,
    @Field() required String platform,
    @Field() String? recipientName,
    @Field() String? recipientCompany,
    @Field() String? recipientTitle,
  });

  // Campaign Metrics endpoints
  @GET("rest/s1/growerp/100/CampaignMetrics")
  Future<CampaignMetrics> getCampaignMetrics({
    @Query('marketingCampaignId') required String marketingCampaignId,
  });

  // Platform Configuration endpoints
  @GET("rest/s1/growerp/100/PlatformConfigurations")
  Future<PlatformConfigurations> listPlatformConfigurations();

  @GET("rest/s1/growerp/100/PlatformConfiguration")
  Future<PlatformConfiguration> getPlatformConfiguration({
    @Query('platform') required String platform,
  });

  @POST("rest/s1/growerp/100/PlatformConfiguration")
  Future<PlatformConfiguration> createPlatformConfiguration({
    @Field() required String platform,
    @Field() String? isEnabled,
    @Field() int? dailyLimit,
    @Field() String? apiKey,
    @Field() String? apiSecret,
    @Field() String? username,
    @Field() String? password,
  });

  @PATCH("rest/s1/growerp/100/PlatformConfiguration")
  Future<PlatformConfiguration> updatePlatformConfiguration({
    @Field() required String configId,
    @Field() String? isEnabled,
    @Field() int? dailyLimit,
    @Field() String? apiKey,
    @Field() String? apiSecret,
    @Field() String? username,
    @Field() String? password,
  });

  @DELETE("rest/s1/growerp/100/PlatformConfiguration")
  Future<void> deletePlatformConfiguration({
    @Query('configId') required String configId,
  });

  /// Check the stored credentials against the platform and record the outcome
  /// on the configuration. Returns success/message/lastCheckDate.
  @POST("rest/s1/growerp/100/PlatformConfiguration/verify")
  Future<dynamic> verifyPlatformConfiguration({
    @Field() required String configId,
  });

  // Send outreach email
  @POST("rest/s1/growerp/100/OutreachEmail")
  Future<OutreachMessage> sendOutreachEmail({
    @Field() required String marketingCampaignId,
    @Field() required String toEmail,
    @Field() String? toName,
    @Field() required String subject,
    @Field() required String body,
    @Field() String? bodyContentType,
  });

  // Generate platform-specific message with AI
  @POST("rest/s1/growerp/100/GeneratePlatformMessage")
  Future<Map<String, String>> generatePlatformMessage({
    @Field() required String campaignTemplate,
    @Field() required String platform,
    @Field() required String actionType,
  });
}
