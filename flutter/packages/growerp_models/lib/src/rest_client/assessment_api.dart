import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin AssessmentApi {
  // Assessment endpoints
  @GET("rest/s1/growerp/100/AssessmentComplete")
  Future<Assessment> getAssessmentComplete({
    @Query('assessmentId') String? assessmentId,
    @Query('pseudoId') String? pseudoId,
    @Query('ownerPartyId') String? ownerPartyId,
  });

  @GET("rest/s1/growerp/100/Assessment")
  Future<Assessments> getAssessment({
    @Query('assessmentId') String? assessmentId,
    @Query('pseudoId') String? pseudoId,
    @Query('ownerPartyId') String? ownerPartyId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
    @Query('statusId') String? statusId,
  });

  @GET("rest/s1/growerp/100/Assessment")
  Future<Assessments> searchAssessments({
    @Query('search') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('statusId') String? statusId,
  });

  @POST("rest/s1/growerp/100/Assessment")
  Future<Assessment> createAssessment({
    @Field() String? pseudoId,
    @Field() required String assessmentName,
    @Field() String? description,
    @Field() String status = 'ACTIVE',
  });

  @PATCH("rest/s1/growerp/100/Assessment")
  Future<Assessment> updateAssessment({
    @Field() required String assessmentId,
    @Field() String? pseudoId,
    @Field() String? assessmentName,
    @Field() String? description,
    @Field() String? status,
  });

  @DELETE("rest/s1/growerp/100/Assessment")
  Future<void> deleteAssessment({@Field() required String assessmentId});

  @POST("rest/s1/growerp/100/Assessment/submit")
  Future<AssessmentResult> submitAssessment({
    @Field() required String assessmentId,
    @Field('answersData') required String answers,
    @Field() required String respondentName,
    @Field() required String respondentEmail,
    @Field() String? respondentPhone,
    @Field() String? respondentCompany,
    @Field() String? ownerPartyId,
    @Field() String? campaignId,
  });

  // Assessment Question endpoints
  // question and options
  @GET("rest/s1/growerp/100/Assessment/Questions")
  Future<AssessmentQuestions> getAssessmentQuestions({
    @Query('assessmentId') required String assessmentId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/Assessment/Question")
  Future<AssessmentQuestions> getAssessmentQuestion({
    @Query('assessmentId') required String assessmentId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Assessment/Question")
  Future<AssessmentQuestion> createAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionText,
    @Field() String? questionDescription,
    @Field() String? questionType,
    @Field() int? questionSequence,
    @Field() String? isRequired,
    @Field() List<Map<String, dynamic>>? options,
  });

  @PATCH("rest/s1/growerp/100/Assessment/Question")
  Future<AssessmentQuestion> updateAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionId,
    @Field() String? questionText,
    @Field() String? questionDescription,
    @Field() String? questionType,
    @Field() int? questionSequence,
    @Field() String? isRequired,
    @Field() List<Map<String, dynamic>>? options,
  });

  @DELETE("rest/s1/growerp/100/Assessment/Question")
  Future<void> deleteAssessmentQuestion({
    @Field() required String assessmentId,
    @Field() required String questionId,
  });
  // Assessment Question Option endpoints
  // Assessment Scoring Threshold endpoints
  @GET("rest/s1/growerp/100/Assessment/Threshold")
  Future<ScoringThresholds> getAssessmentThresholds({
    @Query('assessmentId') required String assessmentId,
  });

  @PATCH("rest/s1/growerp/100/Assessment/Threshold")
  Future<ScoringThresholds> updateAssessmentThresholds({
    @Field() required String assessmentId,
    @Field() required List<ScoringThreshold> thresholds,
  });

  // Assessment Result endpoints
  @GET("rest/s1/growerp/100/Assessment/Results")
  Future<AssessmentResults> getAssessmentResults({
    @Query('assessmentId') String? assessmentId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/AllAssessment/Results")
  Future<AssessmentResults> getAllAssessmentResults({
    @Query('start') int? start,
    @Query('limit') int? limit,
  });
}
