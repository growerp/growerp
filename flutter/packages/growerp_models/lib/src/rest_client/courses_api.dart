import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin CoursesApi {
  // Course Management
  @GET("rest/s1/growerp/100/Courses")
  Future<Courses> listCourses({
    @Query('filter') String? filter,
    @Query('status') String? status,
    @Query('productId') String? productId,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/Course")
  Future<dynamic> getCourse({@Query('courseId') required String courseId});

  // Learner access: published courses only, lesson content gated by subscription
  @GET("rest/s1/growerp/100/CourseCatalog")
  Future<Courses> listCourseCatalog({
    @Query('filter') String? filter,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/CourseCatalog")
  Future<dynamic> getCourseCatalog({
    @Query('courseId') required String courseId,
  });

  // Learner: module quiz (no answers), scoring, completion certificate
  @GET("rest/s1/growerp/100/CourseCatalog/Quiz")
  Future<CourseQuiz> getCourseQuiz({
    @Query('courseId') required String courseId,
    @Query('moduleId') required String moduleId,
  });

  @POST("rest/s1/growerp/100/CourseCatalog/Quiz")
  Future<CourseQuizResult> submitCourseQuiz({
    @Field() required String courseId,
    @Field() required String moduleId,
    @Field() required List<int?> answers,
    @Field() bool? placement,
  });

  /// Learner: AI tutor answer on the current lesson; returns {answer}
  @POST("rest/s1/growerp/100/CourseCatalog/Tutor")
  Future<dynamic> courseTutor({@Body() required Map<String, dynamic> data});

  /// Learner: an exercise with the own submissions
  @GET("rest/s1/growerp/100/CourseCatalog/Exercise")
  Future<CourseExerciseDetail> getCourseExercise({
    @Query('courseId') required String courseId,
    @Query('exerciseId') required String exerciseId,
  });

  /// Learner: hand in an answer, graded by the AI
  @POST("rest/s1/growerp/100/CourseCatalog/Exercise")
  Future<CourseExerciseSubmitResult> submitCourseExercise({
    @Field() required String courseId,
    @Field() required String exerciseId,
    @Field() required String answer,
  });

  /// Learner: what to do next; {recommendation}
  @GET("rest/s1/growerp/100/CourseCatalog/Recommendation")
  Future<dynamic> getCourseRecommendation({
    @Query('courseId') required String courseId,
  });

  /// Learner: join the course discussion; returns {chatRoomId}
  @POST("rest/s1/growerp/100/CourseCatalog/Discussion")
  Future<dynamic> joinCourseDiscussion({@Field() required String courseId});

  @GET("rest/s1/growerp/100/CourseCatalog/Certificate")
  Future<dynamic> getCourseCertificate({
    @Query('courseId') required String courseId,
  });

  @POST("rest/s1/growerp/100/Course")
  Future<dynamic> createCourse({@Body() required Map<String, dynamic> data});

  @PATCH("rest/s1/growerp/100/Course")
  Future<dynamic> updateCourse({@Body() required Map<String, dynamic> data});

  @DELETE("rest/s1/growerp/100/Course")
  Future<dynamic> deleteCourse({@Query('courseId') required String courseId});

  /// The full course as a JSON file: returns {courseJson, fileName}
  @GET("rest/s1/growerp/100/Course/Export")
  Future<dynamic> exportCourse({@Query('courseId') required String courseId});

  /// A new draft course from an exported file: returns {courseId, pseudoId}
  @POST("rest/s1/growerp/100/Course/Import")
  Future<dynamic> importCourse({@Field() required String courseJson});

  @POST("rest/s1/growerp/100/Course/Module")
  Future<dynamic> createCourseModule({
    @Body() required Map<String, dynamic> data,
  });

  @PATCH("rest/s1/growerp/100/Course/Module")
  Future<dynamic> updateCourseModule({
    @Body() required Map<String, dynamic> data,
  });

  @DELETE("rest/s1/growerp/100/Course/Module")
  Future<dynamic> deleteCourseModule({
    @Query('moduleId') required String moduleId,
  });

  @POST("rest/s1/growerp/100/Course/Lesson")
  Future<dynamic> createCourseLesson({
    @Body() required Map<String, dynamic> data,
  });

  @PATCH("rest/s1/growerp/100/Course/Lesson")
  Future<dynamic> updateCourseLesson({
    @Body() required Map<String, dynamic> data,
  });

  @DELETE("rest/s1/growerp/100/Course/Lesson")
  Future<dynamic> deleteCourseLesson({
    @Query('lessonId') required String lessonId,
  });

  @POST("rest/s1/growerp/100/Course/generateMediaWithAI")
  Future<dynamic> generateCourseMedia({
    @Body() required Map<String, dynamic> data,
  });

  // Authoring of module quiz questions
  @POST("rest/s1/growerp/100/Course/QuizQuestion")
  Future<dynamic> createCourseQuizQuestion({
    @Body() required Map<String, dynamic> data,
  });

  @PATCH("rest/s1/growerp/100/Course/QuizQuestion")
  Future<dynamic> updateCourseQuizQuestion({
    @Body() required Map<String, dynamic> data,
  });

  @DELETE("rest/s1/growerp/100/Course/QuizQuestion")
  Future<dynamic> deleteCourseQuizQuestion({
    @Query('questionId') required String questionId,
  });

  @POST("rest/s1/growerp/100/Course/Exercise")
  Future<dynamic> createCourseExercise({
    @Body() required Map<String, dynamic> data,
  });

  @PATCH("rest/s1/growerp/100/Course/Exercise")
  Future<dynamic> updateCourseExercise({
    @Body() required Map<String, dynamic> data,
  });

  @DELETE("rest/s1/growerp/100/Course/Exercise")
  Future<dynamic> deleteCourseExercise({
    @Query('exerciseId') required String exerciseId,
  });

  /// Authors: learner work of a course, latest first
  @GET("rest/s1/growerp/100/Course/Submission")
  Future<CourseSubmissions> getCourseSubmissions({
    @Query('courseId') required String courseId,
    @Query('exerciseId') String? exerciseId,
    @Query('userId') String? userId,
    @Query('needsReview') bool? needsReview,
    @Query('searchString') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  /// Authors: instructor feedback and score on a submission
  @PATCH("rest/s1/growerp/100/Course/Submission")
  Future<dynamic> reviewCourseSubmission({
    @Field() required String submissionId,
    @Field() required int instructorScore,
    @Field() String? instructorFeedback,
  });

  /// Authors: earlier versions of a lesson
  @GET("rest/s1/growerp/100/Course/Lesson/History")
  Future<CourseLessonVersions> getCourseLessonHistory({
    @Query('lessonId') required String lessonId,
  });

  /// Authors: put an earlier version of a lesson back
  @POST("rest/s1/growerp/100/Course/Lesson/History")
  Future<dynamic> restoreCourseLesson({@Field() required String historyId});

  @GET("rest/s1/growerp/100/Course/AiJob")
  Future<CourseAiJobs> getCourseAiJobs({
    @Query('jobId') String? jobId,
    @Query('courseId') String? courseId,
  });

  /// Queue an AI job (OUTLINE, LESSONS); poll [getCourseAiJobs] for progress
  @POST("rest/s1/growerp/100/Course/AiJob")
  Future<dynamic> createCourseAiJob({
    @Body() required Map<String, dynamic> data,
  });

  @GET("rest/s1/growerp/100/CourseMedia")
  Future<CourseMediaList> listCourseMedia({
    @Query('courseId') String? courseId,
    @Query('platform') String? platform,
  });

  @PATCH("rest/s1/growerp/100/CourseMedia")
  Future<dynamic> updateCourseMedia({
    @Body() required Map<String, dynamic> data,
  });

  @GET("rest/s1/growerp/100/CourseProgress")
  Future<dynamic> getCourseProgress({
    @Query('courseId') required String courseId,
  });

  @PATCH("rest/s1/growerp/100/CourseProgress")
  Future<dynamic> updateCourseProgress({
    @Body() required Map<String, dynamic> data,
  });

  @POST("rest/s1/growerp/100/GenerateVideo")
  Future<dynamic> generateVideoFromScript({
    @Body() required Map<String, dynamic> data,
  });

  @GET("rest/s1/growerp/100/CourseParticipants")
  Future<CourseParticipants> getCourseParticipants({
    @Query('courseId') required String courseId,
  });

  @GET("rest/s1/growerp/100/MyCourseSubscriptions")
  Future<Courses> getMyCourseSubscriptions();

  @GET("rest/s1/growerp/100/AllCourseParticipants")
  Future<CourseParticipants> getAllCourseParticipants({
    @Query('filter') String? filter,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/CourseLearner")
  Future<CourseLearners> getCourseLearners({
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/CourseLearner")
  Future<dynamic> addCourseLearner({
    @Field() required String partyId,
    @Field() required String courseId,
  });

  @DELETE("rest/s1/growerp/100/CourseLearner")
  Future<dynamic> removeCourseLearner({
    @Field() required String partyId,
    @Field() required String courseId,
  });
}
