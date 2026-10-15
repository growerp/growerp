import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin MarketingApi {
  // email nurture sequences
  @GET("rest/s1/growerp/100/EmailSequence")
  Future<EmailSequences> getEmailSequence({
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('emailSequenceId') String? emailSequenceId,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/EmailSequence")
  Future<EmailSequence> createEmailSequence({
    @Field() required EmailSequence emailSequence,
  });

  @PATCH("rest/s1/growerp/100/EmailSequence")
  Future<EmailSequence> updateEmailSequence({
    @Field() required EmailSequence emailSequence,
  });

  @DELETE("rest/s1/growerp/100/EmailSequence")
  Future<void> deleteEmailSequence({
    @Field() required EmailSequence emailSequence,
  });

  @GET("rest/s1/growerp/100/EmailSequenceMember")
  Future<EmailSequenceEnrollments> getEmailSequenceEnrollments({
    @Query('emailSequenceId') required String emailSequenceId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/EmailSequenceMember")
  Future<void> addEmailSequenceMember({
    @Field() required String emailSequenceId,
    @Field() required String emailAddress,
    @Field() String? firstName,
  });

  @PATCH("rest/s1/growerp/100/EmailSequenceMember")
  Future<void> unsubscribeEmailSequenceMember({
    @Field() required String emailSequenceId,
    @Field() required String enrollmentId,
  });

  @GET("rest/s1/growerp/100/MarketingDashboard")
  Future<MarketingDashboard> getMarketingDashboard();

  @GET("rest/s1/growerp/100/ContentReadStats")
  Future<ContentReadStatsResult> getContentReadStats({
    @Query('searchString') String? searchString,
  });

  @GET("rest/s1/growerp/100/OutreachDashboard")
  Future<OutreachDashboard> getOutreachDashboard();

  @GET("rest/s1/growerp/100/CrmDashboard")
  Future<CrmDashboard> getCrmDashboard();

  @GET("rest/s1/growerp/100/CatalogDashboard")
  Future<CatalogDashboard> getCatalogDashboard();

  @GET("rest/s1/growerp/100/OrderDashboard")
  Future<OrderDashboard> getOrderDashboard();

  @GET("rest/s1/growerp/100/InventoryDashboard")
  Future<InventoryDashboard> getInventoryDashboard();

  @GET("rest/s1/growerp/100/AcctSalesDashboard")
  Future<AcctSalesDashboard> getAcctSalesDashboard();

  @GET("rest/s1/growerp/100/AcctPurchaseDashboard")
  Future<AcctPurchaseDashboard> getAcctPurchaseDashboard();

  @GET("rest/s1/growerp/100/LedgerDashboard")
  Future<LedgerDashboard> getLedgerDashboard();

  @GET("rest/s1/growerp/100/ManufacturingDashboard")
  Future<ManufacturingDashboard> getManufacturingDashboard();

  @GET("rest/s1/growerp/100/AgentControlDashboard")
  Future<AgentControlDashboard> getAgentControlDashboard();

  // social engagement signals
  @GET("rest/s1/growerp/100/SocialEngagement")
  Future<SocialEngagements> getSocialEngagement({
    @Query('postId') String? postId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/SocialEngagement")
  Future<void> createSocialEngagement({
    @Field() required SocialEngagement socialEngagement,
  });

  @POST("rest/s1/growerp/100/SocialEngagement/Convert")
  Future<void> convertEngagementToLead({
    @Field() required String engagementId,
    @Field() required String email,
  });

  @POST("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> createOpportunity({
    @Field() required Opportunity opportunity,
  });

  @PATCH("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> updateOpportunity({
    @Field() required Opportunity opportunity,
  });

  @DELETE("rest/s1/growerp/100/Opportunity")
  Future<Opportunity> deleteOpportunity({
    @Field() required Opportunity opportunity,
  });

  // Marketing Persona endpoints
  @GET("rest/s1/growerp/100/MarketingPersonas")
  Future<Personas> getMarketingPersonas({
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/MarketingPersona")
  Future<Persona> createMarketingPersona({
    @Field() required String name,
    @Field() String? pseudoId,
    @Field() String? demographics,
    @Field() String? painPoints,
    @Field() String? goals,
    @Field() String? toneOfVoice,
  });

  @PATCH("rest/s1/growerp/100/MarketingPersona")
  Future<Persona> updateMarketingPersona({
    @Field() required String personaId,
    @Field() String? pseudoId,
    @Field() String? name,
    @Field() String? demographics,
    @Field() String? painPoints,
    @Field() String? goals,
    @Field() String? toneOfVoice,
  });

  @DELETE("rest/s1/growerp/100/MarketingPersona")
  Future<void> deleteMarketingPersona({@Field() required String personaId});

  @POST("rest/s1/growerp/100/MarketingPersona/generateWithAI")
  Future<Persona> generateMarketingPersonaWithAI({
    @Field() required String businessDescription,
    @Field() String? targetMarket,
  });

  // Content Plan endpoints
  @GET("rest/s1/growerp/100/ContentPlans")
  Future<ContentPlans> getContentPlans({
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/ContentPlan")
  Future<ContentPlan> createContentPlan({
    @Field() String? pseudoId,
    @Field() String? personaId,
    @Field() int? weekStartDate,
    @Field() String? theme,
  });

  @PATCH("rest/s1/growerp/100/ContentPlan")
  Future<ContentPlan> updateContentPlan({
    @Field() required String planId,
    @Field() String? pseudoId,
    @Field() String? personaId,
    @Field() int? weekStartDate,
    @Field() String? theme,
  });

  @DELETE("rest/s1/growerp/100/ContentPlan")
  Future<void> deleteContentPlan({@Field() required String planId});

  @POST("rest/s1/growerp/100/ContentPlan/generateWithAI")
  Future<ContentPlan> generateContentPlanWithAI({
    @Field() required String personaId,
    @Field() int? weekStartDate,
    @Field() int? weeks,
    @Field() String? planFormat,
    @Field() String? theme,
  });

  // Social Post endpoints
  @GET("rest/s1/growerp/100/SocialPosts")
  Future<SocialPosts> getSocialPosts({
    @Query('searchString') String? searchString,
    @Query('planId') String? planId,
    @Query('masterContentId') String? masterContentId,

    /// Epoch milliseconds: only posts scheduled at or after this moment.
    @Query('fromDate') int? fromDate,

    /// Epoch milliseconds, exclusive: only posts scheduled before this moment.
    @Query('thruDate') int? thruDate,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/SocialPost")
  Future<SocialPost> createSocialPost({
    @Field() String? pseudoId,
    @Field() String? planId,
    @Field() String? type,
    @Field() String? platform,
    @Field() String? headline,
    @Field() String? draftContent,
    @Field() String? finalContent,
    @Field() String? status,
    @Field() int? scheduledDate,
  });

  @PATCH("rest/s1/growerp/100/SocialPost")
  Future<SocialPost> updateSocialPost({
    @Field() required String postId,
    @Field() String? pseudoId,
    @Field() String? planId,
    @Field() String? type,
    @Field() String? platform,
    @Field() String? headline,
    @Field() String? draftContent,
    @Field() String? finalContent,
    @Field() String? status,
    @Field() int? scheduledDate,
  });

  @DELETE("rest/s1/growerp/100/SocialPost")
  Future<void> deleteSocialPost({@Field() required String postId});

  @POST("rest/s1/growerp/100/SocialPost/draftWithAI")
  Future<SocialPost> draftSocialPostWithAI({@Field() required String postId});

  @POST("rest/s1/growerp/100/SocialPost/publish")
  Future<SocialPost> publishSocialPost({@Field() required String postId});

  @POST("rest/s1/growerp/100/SocialPost/publishScheduled")
  Future<void> publishScheduledSocialPosts();

  // Master Content endpoints (author once -> adapt per platform)
  @GET("rest/s1/growerp/100/MasterContents")
  Future<MasterContents> getMasterContents({
    @Query('searchString') String? searchString,
    @Query('planId') String? planId,
    @Query('contentType') String? contentType,
    @Query('status') String? status,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/MasterContent")
  Future<MasterContent> createMasterContent({
    @Field() String? pseudoId,
    @Field() String? planId,
    @Field() String? contentType,
    @Field() String? pnpType,
    @Field() String? title,
    @Field() String? body,
    @Field() String? callToAction,
    @Field() String? targetUrl,
    @Field() String? teaserMode,
    @Field() String? ctaUrl,
    @Field() String? status,
    @Field() String? image,
  });

  @PATCH("rest/s1/growerp/100/MasterContent")
  Future<MasterContent> updateMasterContent({
    @Field() required String masterContentId,
    @Field() String? pseudoId,
    @Field() String? planId,
    @Field() String? contentType,
    @Field() String? pnpType,
    @Field() String? title,
    @Field() String? body,
    @Field() String? callToAction,
    @Field() String? targetUrl,
    @Field() String? teaserMode,
    @Field() String? ctaUrl,
    @Field() String? status,
    @Field() String? brief,

    /// base64; '' removes the image, null keeps it
    @Field() String? image,
  });

  @DELETE("rest/s1/growerp/100/MasterContent")
  Future<void> deleteMasterContent({@Field() required String masterContentId});

  /// The related image in full size: returns {image (base64)}
  @GET("rest/s1/growerp/100/MasterContent/image")
  Future<dynamic> getMasterContentImage({
    @Query('masterContentId') required String masterContentId,
  });

  /// AI-make the related image: returns {image (small, base64), imageError}
  @POST("rest/s1/growerp/100/MasterContent/generateImage")
  Future<dynamic> generateMasterContentImage({
    @Field() required String masterContentId,
  });

  /// All master content with images as a ZIP: returns {zip (base64), fileName}
  @GET("rest/s1/growerp/100/MasterContent/Export")
  Future<dynamic> exportMasterContents();

  /// Load a ZIP made by [exportMasterContents]: returns {createdCount, updatedCount}
  @POST("rest/s1/growerp/100/MasterContent/Import")
  Future<dynamic> importMasterContents({@Field() required String zip});

  @POST("rest/s1/growerp/100/MasterContent/generateWithAI")
  Future<MasterContent> generateMasterContentWithAI({
    /// a PLANNED piece of a content plan: written in place from its brief
    @Field() String? masterContentId,
    @Field() String? personaId,
    @Field() String? planId,
    @Field() String? contentType,
    @Field() String? pnpType,
    @Field() String? title,
    @Field() String? brief,
    @Field() String? targetUrl,
  });

  @POST("rest/s1/growerp/100/MasterContent/adaptForPlatform")
  Future<dynamic> adaptContentForPlatform({
    @Field() required String masterContentId,
    @Field() List<String>? platforms,
    @Field() String? campaignId,
    @Field() int? scheduledDate,
  });

  // Content ideas: raw text and/or an article URL -> ~500 word website article
  @GET("rest/s1/growerp/100/ContentIdeas")
  Future<ContentIdeas> getContentIdeas({
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/ContentIdea")
  Future<ContentIdea> createContentIdea({
    @Field() String? title,
    @Field() String? rawText,
    @Field() String? sourceUrl,
  });

  @PATCH("rest/s1/growerp/100/ContentIdea")
  Future<ContentIdea> updateContentIdea({
    @Field() required String ideaId,
    @Field() String? title,
    @Field() String? rawText,
    @Field() String? sourceUrl,
  });

  /// Put the ideas in this order (first = next to use)
  @POST("rest/s1/growerp/100/ContentIdea/reorder")
  Future<void> reorderContentIdeas({@Field() required List<String> ideaIds});

  @DELETE("rest/s1/growerp/100/ContentIdea")
  Future<void> deleteContentIdea({@Field() required String ideaId});

  /// Writes the article; returns masterContentId, pseudoId, title, targetUrl
  @POST("rest/s1/growerp/100/ContentIdea/writeArticle")
  Future<MasterContent> writeArticleFromIdea({
    @Field() required String ideaId,
    @Field() String? pnpType,
  });

  @POST("rest/s1/growerp/100/MasterContent/approve")
  Future<MasterContent> approveMasterContent({
    @Field() required String masterContentId,
    @Field() String? approve,
  });
}
