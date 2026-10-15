import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin LandingPageApi {
  // Landing Page endpoints
  @GET("rest/s1/growerp/100/LandingPage")
  Future<LandingPages> getLandingPages({
    @Query('landingPageId') String? landingPageId,
    @Query('pseudoId') String? pseudoId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('statusId') String? statusId,
  });

  // Public landing page endpoint (anonymous access)
  @GET("rest/s1/growerp/100/LandingPagePublic")
  Future<LandingPage> getLandingPage({
    @Query('landingPageId') String? landingPageId,
    @Query('pseudoId') String? pseudoId,
    @Query('ownerPartyId') String? ownerPartyId,
  });

  @POST("rest/s1/growerp/100/LandingPage")
  Future<LandingPage> createLandingPage({
    @Field() required String title,
    @Field() String? pseudoId,
    @Field() String? hookType,
    @Field() String? headline,
    @Field() String? subheading,
    @Field() String? privacyPolicyUrl,
    @Field() String? ctaActionType,
    @Field() String? ctaAssessmentId,
    @Field() String? ctaButtonLink,
    @Field() String? ctaFormId,
    @Field() String? theme,
    @Field() String status = 'DRAFT',
  });

  @PATCH("rest/s1/growerp/100/LandingPage")
  Future<LandingPage> updateLandingPage({
    @Query('landingPageId') required String landingPageId,
    @Field() String? pseudoId,
    @Field() String? title,
    @Field() String? hookType,
    @Field() String? headline,
    @Field() String? subheading,
    @Field() String? ctaActionType,
    @Field() String? ctaAssessmentId,
    @Field() String? ctaButtonLink,
    @Field() String? ctaFormId,
    @Field() String? theme,
    @Field() String? privacyPolicyUrl,
    @Field() String? status,
  });

  @DELETE("rest/s1/growerp/100/LandingPage")
  Future<void> deleteLandingPage({
    @Query('landingPageId') required String landingPageId,
  });

  @POST("rest/s1/growerp/100/LandingPage/publish")
  Future<LandingPage> publishLandingPage({
    @Query('landingPageId') required String landingPageId,
  });

  // ============================================
  // AI LANDING PAGE GENERATION ENDPOINTS
  // ============================================

  @POST("rest/s1/growerp/100/LandingPage/generateWithAI")
  @FormUrlEncoded()
  Future<LandingPageGenerationResponse> generateLandingPageWithAI({
    @Field() required String businessDescription,
    @Field() String? targetAudience,
    @Field() String? industry,
    @Field() String tone = 'professional',
    @Field() int numSections = 5,
    @Field() String? downloadUrl,
    @Field() String? downloadDescription,
  });

  // ============================================
  // PAGE SECTION ENDPOINTS
  // ============================================

  @GET("rest/s1/growerp/100/LandingPage/Section")
  Future<LandingPageSections> getPageSections({
    @Query('landingPageId') required String landingPageId,
  });

  @POST("rest/s1/growerp/100/LandingPage/Section")
  Future<LandingPageSection> createPageSection({
    @Field() required String landingPageId,
    @Field() required String sectionTitle,
    @Field() String? sectionDescription,
    @Field() String? sectionImageUrl,
    @Field() String? sectionType,
    @Field() String? contentJson,
    @Field() int? sectionSequence,
  });

  @PATCH("rest/s1/growerp/100/LandingPage/Section")
  Future<LandingPageSection> updatePageSection({
    @Query('landingPageId') required String landingPageId,
    @Query('pageSectionId') required String pageSectionId,
    @Field() String? sectionTitle,
    @Field() String? sectionDescription,
    @Field() String? sectionImageUrl,
    @Field() String? sectionType,
    @Field() String? contentJson,
    @Field() int? sectionSequence,
  });

  @DELETE("rest/s1/growerp/100/LandingPage/Section")
  Future<void> deletePageSection({
    @Query('landingPageId') required String landingPageId,
    @Query('pageSectionId') required String pageSectionId,
  });

  // ============================================
  // CREDIBILITY INFO ENDPOINTS (Nested under LandingPage)
  // ============================================

  @GET("rest/s1/growerp/100/LandingPage/Credibility")
  Future<CredibilityInfoList> getCredibilityInfo({
    @Query('landingPageId') required String landingPageId,
  });

  @POST("rest/s1/growerp/100/LandingPage/Credibility")
  Future<CredibilityInfo> createCredibilityInfo({
    @Field() required String landingPageId,
    @Field() String? creatorBio,
    @Field() String? backgroundText,
    @Field() String? creatorImageUrl,
    @Field() String? statisticsJson,
  });

  @PATCH("rest/s1/growerp/100/LandingPage/Credibility")
  Future<CredibilityInfo> updateCredibilityInfo({
    @Field() required String landingPageId,
    @Field() required String credibilityInfoId,
    @Field() String? pseudoId,
    @Field() String? creatorBio,
    @Field() String? backgroundText,
    @Field() String? creatorImageUrl,
    @Field() String? statisticsJson,
  });

  @DELETE("rest/s1/growerp/100/LandingPage/Credibility")
  Future<void> deleteCredibilityInfo({
    @Field() required String landingPageId,
    @Field() required String credibilityInfoId,
  });
}
