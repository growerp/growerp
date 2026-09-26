/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';
import '../json_converters.dart';
import 'assessment_model.dart' show NullableTimestampConverter;

part 'course_model.g.dart';

/// Difficulty level for courses
enum CourseDifficulty {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('INTERMEDIATE')
  intermediate,
  @JsonValue('ADVANCED')
  advanced,
}

/// Status for courses
enum CourseStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('PUBLISHED')
  published,
  @JsonValue('ARCHIVED')
  archived,
}

/// Platform for media generation
enum MediaPlatform {
  @JsonValue('LINKEDIN')
  linkedin,
  @JsonValue('MEDIUM')
  medium,
  @JsonValue('EMAIL')
  email,
  @JsonValue('YOUTUBE')
  youtube,
  @JsonValue('TWITTER')
  twitter,
  @JsonValue('SUBSTACK')
  substack,
  @JsonValue('INAPP')
  inapp,
}

/// Type of generated media
enum MediaType {
  @JsonValue('POST')
  post,
  @JsonValue('ARTICLE')
  article,
  @JsonValue('SEQUENCE')
  sequence,
  @JsonValue('SCRIPT')
  script,
  @JsonValue('THREAD')
  thread,
  @JsonValue('TUTORIAL')
  tutorial,
}

/// Media status
enum MediaStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('REVIEWED')
  reviewed,
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('PUBLISHED')
  published,
}

/// Course model
@JsonSerializable()
class Course {
  final String? courseId;
  final String? pseudoId;
  final String? ownerPartyId;
  final String? productId;
  final String? productPseudoId;
  final String title;
  final String? description;
  final String? objectives;
  final String? targetPersonaId;

  /// Free-text target audience, the AI writes for it
  final String? audience;
  final CourseDifficulty? difficulty;
  final int? estimatedDuration;
  final CourseStatus? status;
  final String? coverImageUrl;
  @NullableTimestampConverter()
  final DateTime? createdDate;
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;
  final List<CourseModule>? modules;

  /// Count of modules (from view entity for list display)
  final int? moduleCount;

  /// Count of lessons (from view entity for list display)
  final int? lessonCount;

  /// Progress percentage for the current user (0–100), returned by
  /// get#MyCourseSubscriptions for the learner dashboard.
  final int? progressPercent;

  /// Price of the course (from associated product). Null means free.
  final Decimal? price;

  Course({
    this.courseId,
    this.pseudoId,
    this.ownerPartyId,
    this.productId,
    this.productPseudoId,
    required this.title,
    this.description,
    this.objectives,
    this.targetPersonaId,
    this.audience,
    this.difficulty = CourseDifficulty.beginner,
    this.estimatedDuration,
    this.status = CourseStatus.draft,
    this.coverImageUrl,
    this.createdDate,
    this.lastModifiedDate,
    this.modules,
    this.moduleCount,
    this.lessonCount,
    this.progressPercent,
    this.price,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  Course copyWith({
    String? courseId,
    String? pseudoId,
    String? ownerPartyId,
    String? productId,
    String? productPseudoId,
    String? title,
    String? description,
    String? objectives,
    String? targetPersonaId,
    String? audience,
    CourseDifficulty? difficulty,
    int? estimatedDuration,
    CourseStatus? status,
    String? coverImageUrl,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    List<CourseModule>? modules,
    int? moduleCount,
    int? lessonCount,
    int? progressPercent,
    Decimal? price,
  }) => Course(
    courseId: courseId ?? this.courseId,
    pseudoId: pseudoId ?? this.pseudoId,
    ownerPartyId: ownerPartyId ?? this.ownerPartyId,
    productId: productId ?? this.productId,
    productPseudoId: productPseudoId ?? this.productPseudoId,
    title: title ?? this.title,
    description: description ?? this.description,
    objectives: objectives ?? this.objectives,
    targetPersonaId: targetPersonaId ?? this.targetPersonaId,
    audience: audience ?? this.audience,
    difficulty: difficulty ?? this.difficulty,
    estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    status: status ?? this.status,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    createdDate: createdDate ?? this.createdDate,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    modules: modules ?? this.modules,
    moduleCount: moduleCount ?? this.moduleCount,
    lessonCount: lessonCount ?? this.lessonCount,
    progressPercent: progressPercent ?? this.progressPercent,
    price: price ?? this.price,
  );

  @override
  String toString() => 'Course($title)';
}

/// List wrapper for courses
@JsonSerializable()
class Courses {
  final List<Course> courses;

  Courses({required this.courses});

  factory Courses.fromJson(Map<String, dynamic> json) =>
      _$CoursesFromJson(json);
  Map<String, dynamic> toJson() => _$CoursesToJson(this);
}

/// Course Module model
@JsonSerializable()
class CourseModule {
  final String? moduleId;
  final String? pseudoId;
  final String? courseId;
  final String title;
  final String? description;
  final int? sequenceNum;
  final int? estimatedDuration;
  @NullableTimestampConverter()
  final DateTime? createdDate;
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;
  final List<CourseLesson>? lessons;

  /// Presentation of the module, saved with its own update call
  @JsonKey(includeToJson: false)
  final List<CourseSlide>? slides;

  /// Number of quiz questions of this module, 0 is no quiz
  @JsonKey(includeToJson: false)
  final int? quizQuestionCount;

  /// The quiz with answers: only returned to the authors
  @JsonKey(includeToJson: false)
  final List<CourseQuizQuestion>? quizQuestions;

  CourseModule({
    this.moduleId,
    this.pseudoId,
    this.courseId,
    required this.title,
    this.description,
    this.sequenceNum,
    this.estimatedDuration,
    this.createdDate,
    this.lastModifiedDate,
    this.lessons,
    this.slides,
    this.quizQuestionCount,
    this.quizQuestions,
  });

  factory CourseModule.fromJson(Map<String, dynamic> json) =>
      _$CourseModuleFromJson(json);
  Map<String, dynamic> toJson() => _$CourseModuleToJson(this);

  CourseModule copyWith({
    String? moduleId,
    String? pseudoId,
    String? courseId,
    String? title,
    String? description,
    int? sequenceNum,
    int? estimatedDuration,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    List<CourseLesson>? lessons,
  }) => CourseModule(
    moduleId: moduleId ?? this.moduleId,
    pseudoId: pseudoId ?? this.pseudoId,
    courseId: courseId ?? this.courseId,
    title: title ?? this.title,
    description: description ?? this.description,
    sequenceNum: sequenceNum ?? this.sequenceNum,
    estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    createdDate: createdDate ?? this.createdDate,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    lessons: lessons ?? this.lessons,
    slides: slides,
    quizQuestionCount: quizQuestionCount,
    quizQuestions: quizQuestions,
  );

  @override
  String toString() => 'CourseModule($title)';
}

/// List wrapper for modules
@JsonSerializable()
class CourseModules {
  final List<CourseModule> modules;

  CourseModules({required this.modules});

  factory CourseModules.fromJson(Map<String, dynamic> json) =>
      _$CourseModulesFromJson(json);
  Map<String, dynamic> toJson() => _$CourseModulesToJson(this);
}

/// Course Lesson model
@JsonSerializable()
class CourseLesson {
  final String? lessonId;
  final String? pseudoId;
  final String? moduleId;
  final String? courseId;
  final String title;
  final String? content; // Markdown content
  @StringListConverter()
  final List<String>? keyPoints;
  final int? sequenceNum;
  final int? estimatedDuration;
  final String? videoUrl;
  final String? imageUrl;
  @NullableTimestampConverter()
  final DateTime? createdDate;
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  CourseLesson({
    this.lessonId,
    this.pseudoId,
    this.moduleId,
    this.courseId,
    required this.title,
    this.content,
    this.keyPoints,
    this.sequenceNum,
    this.estimatedDuration,
    this.videoUrl,
    this.imageUrl,
    this.createdDate,
    this.lastModifiedDate,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) =>
      _$CourseLessonFromJson(json);
  Map<String, dynamic> toJson() => _$CourseLessonToJson(this);

  CourseLesson copyWith({
    String? lessonId,
    String? pseudoId,
    String? moduleId,
    String? courseId,
    String? title,
    String? content,
    List<String>? keyPoints,
    int? sequenceNum,
    int? estimatedDuration,
    String? videoUrl,
    String? imageUrl,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) => CourseLesson(
    lessonId: lessonId ?? this.lessonId,
    pseudoId: pseudoId ?? this.pseudoId,
    moduleId: moduleId ?? this.moduleId,
    courseId: courseId ?? this.courseId,
    title: title ?? this.title,
    content: content ?? this.content,
    keyPoints: keyPoints ?? this.keyPoints,
    sequenceNum: sequenceNum ?? this.sequenceNum,
    estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    videoUrl: videoUrl ?? this.videoUrl,
    imageUrl: imageUrl ?? this.imageUrl,
    createdDate: createdDate ?? this.createdDate,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
  );

  @override
  String toString() => 'CourseLesson($title)';
}

/// List wrapper for lessons
@JsonSerializable()
class CourseLessons {
  final List<CourseLesson> lessons;

  CourseLessons({required this.lessons});

  factory CourseLessons.fromJson(Map<String, dynamic> json) =>
      _$CourseLessonsFromJson(json);
  Map<String, dynamic> toJson() => _$CourseLessonsToJson(this);
}

/// Course Media model (AI-generated content)
@JsonSerializable()
class CourseMedia {
  final String? mediaId;
  final String? pseudoId;
  final String? ownerPartyId;
  final String? courseId;
  final String? moduleId;
  final String? lessonId;
  final MediaPlatform? platform;
  final MediaType? mediaType;
  final String? title;
  final String? generatedContent;
  final String? editedContent;
  final MediaStatus? status;
  @NullableTimestampConverter()
  final DateTime? scheduledDate;
  @NullableTimestampConverter()
  final DateTime? publishedDate;
  @NullableTimestampConverter()
  final DateTime? createdDate;
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  CourseMedia({
    this.mediaId,
    this.pseudoId,
    this.ownerPartyId,
    this.courseId,
    this.moduleId,
    this.lessonId,
    this.platform,
    this.mediaType,
    this.title,
    this.generatedContent,
    this.editedContent,
    this.status = MediaStatus.draft,
    this.scheduledDate,
    this.publishedDate,
    this.createdDate,
    this.lastModifiedDate,
  });

  factory CourseMedia.fromJson(Map<String, dynamic> json) =>
      _$CourseMediaFromJson(json);
  Map<String, dynamic> toJson() => _$CourseMediaToJson(this);

  /// Get the content to display (edited if available, otherwise generated)
  String get displayContent => editedContent ?? generatedContent ?? '';

  CourseMedia copyWith({
    String? mediaId,
    String? pseudoId,
    String? ownerPartyId,
    String? courseId,
    String? moduleId,
    String? lessonId,
    MediaPlatform? platform,
    MediaType? mediaType,
    String? title,
    String? generatedContent,
    String? editedContent,
    MediaStatus? status,
    DateTime? scheduledDate,
    DateTime? publishedDate,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) => CourseMedia(
    mediaId: mediaId ?? this.mediaId,
    pseudoId: pseudoId ?? this.pseudoId,
    ownerPartyId: ownerPartyId ?? this.ownerPartyId,
    courseId: courseId ?? this.courseId,
    moduleId: moduleId ?? this.moduleId,
    lessonId: lessonId ?? this.lessonId,
    platform: platform ?? this.platform,
    mediaType: mediaType ?? this.mediaType,
    title: title ?? this.title,
    generatedContent: generatedContent ?? this.generatedContent,
    editedContent: editedContent ?? this.editedContent,
    status: status ?? this.status,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    publishedDate: publishedDate ?? this.publishedDate,
    createdDate: createdDate ?? this.createdDate,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
  );

  @override
  String toString() => 'CourseMedia($title - $platform)';
}

/// List wrapper for course media
@JsonSerializable()
class CourseMediaList {
  final List<CourseMedia> mediaList;

  CourseMediaList({required this.mediaList});

  factory CourseMediaList.fromJson(Map<String, dynamic> json) =>
      _$CourseMediaListFromJson(json);
  Map<String, dynamic> toJson() => _$CourseMediaListToJson(this);
}

/// Course Progress model
@JsonSerializable()
class CourseProgress {
  final String? progressId;
  final String? userId;
  final String? courseId;
  final String? currentLessonId;
  @StringListConverter()
  final List<String>? completedLessons;
  final int? progressPercent;

  /// Best quiz score percent per moduleId
  @JsonKey(fromJson: _quizScoresFromJson, includeToJson: false)
  final Map<String, int>? quizScores;
  @NullableTimestampConverter()
  final DateTime? startedDate;
  @NullableTimestampConverter()
  final DateTime? lastAccessDate;
  @NullableTimestampConverter()
  final DateTime? completedDate;

  CourseProgress({
    this.progressId,
    this.userId,
    this.courseId,
    this.currentLessonId,
    this.completedLessons,
    this.progressPercent = 0,
    this.quizScores,
    this.startedDate,
    this.lastAccessDate,
    this.completedDate,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressFromJson(json);
  Map<String, dynamic> toJson() => _$CourseProgressToJson(this);

  bool isLessonCompleted(String lessonId) =>
      completedLessons?.contains(lessonId) ?? false;

  bool get isCompleted => progressPercent == 100;

  /// A module quiz counts as passed with this score or more
  static const quizPassPercent = 70;

  bool isQuizPassed(String moduleId) =>
      (quizScores?[moduleId] ?? 0) >= quizPassPercent;

  CourseProgress copyWith({
    String? progressId,
    String? userId,
    String? courseId,
    String? currentLessonId,
    List<String>? completedLessons,
    int? progressPercent,
    Map<String, int>? quizScores,
    DateTime? startedDate,
    DateTime? lastAccessDate,
    DateTime? completedDate,
  }) => CourseProgress(
    progressId: progressId ?? this.progressId,
    userId: userId ?? this.userId,
    courseId: courseId ?? this.courseId,
    currentLessonId: currentLessonId ?? this.currentLessonId,
    completedLessons: completedLessons ?? this.completedLessons,
    progressPercent: progressPercent ?? this.progressPercent,
    quizScores: quizScores ?? this.quizScores,
    startedDate: startedDate ?? this.startedDate,
    lastAccessDate: lastAccessDate ?? this.lastAccessDate,
    completedDate: completedDate ?? this.completedDate,
  );

  @override
  String toString() => 'CourseProgress($courseId - $progressPercent%)';
}

/// Course Participant model (admin view of a student's progress in a course)
@JsonSerializable()
class CourseParticipant {
  final String? courseId;
  final String? courseTitle;
  final String? userId;
  final String? partyId;
  final String? firstName;
  final String? lastName;
  final String? username;
  final int? progressPercent;
  @StringListConverter()
  final List<String>? completedLessons;
  @NullableTimestampConverter()
  final DateTime? startedDate;
  @NullableTimestampConverter()
  final DateTime? lastAccessDate;
  @NullableTimestampConverter()
  final DateTime? completedDate;

  CourseParticipant({
    this.courseId,
    this.courseTitle,
    this.userId,
    this.partyId,
    this.firstName,
    this.lastName,
    this.username,
    this.progressPercent = 0,
    this.completedLessons,
    this.startedDate,
    this.lastAccessDate,
    this.completedDate,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  factory CourseParticipant.fromJson(Map<String, dynamic> json) =>
      _$CourseParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$CourseParticipantToJson(this);

  @override
  String toString() => 'CourseParticipant($fullName - $progressPercent%)';
}

/// List wrapper for course participants
@JsonSerializable()
class CourseParticipants {
  final List<CourseParticipant> participants;

  CourseParticipants({required this.participants});

  factory CourseParticipants.fromJson(Map<String, dynamic> json) =>
      _$CourseParticipantsFromJson(json);
  Map<String, dynamic> toJson() => _$CourseParticipantsToJson(this);
}

/// One AI generation run for a course (OUTLINE, LESSONS), polled for progress
@JsonSerializable()
class CourseAiJob {
  final String? jobId;
  final String? courseId;
  final String? jobType;

  /// QUEUED, RUNNING, DONE, ERROR
  final String? status;
  final int? progressPercent;
  final String? statusMessage;
  final String? errorMessage;

  /// AI_ALLOWANCE: no (free) AI tokens left, the company needs its own key
  final String? errorCode;
  @NullableTimestampConverter()
  final DateTime? createdDate;
  @NullableTimestampConverter()
  final DateTime? completedDate;

  CourseAiJob({
    this.jobId,
    this.courseId,
    this.jobType,
    this.status,
    this.progressPercent,
    this.statusMessage,
    this.errorMessage,
    this.errorCode,
    this.createdDate,
    this.completedDate,
  });

  bool get needsAiKey => errorCode == 'AI_ALLOWANCE';

  bool get isRunning => status == 'QUEUED' || status == 'RUNNING';

  factory CourseAiJob.fromJson(Map<String, dynamic> json) =>
      _$CourseAiJobFromJson(json);
  Map<String, dynamic> toJson() => _$CourseAiJobToJson(this);

  @override
  String toString() => 'CourseAiJob($jobType $status $progressPercent%)';
}

/// List wrapper for course AI jobs
@JsonSerializable()
class CourseAiJobs {
  final List<CourseAiJob> courseAiJobs;

  CourseAiJobs({required this.courseAiJobs});

  factory CourseAiJobs.fromJson(Map<String, dynamic> json) =>
      _$CourseAiJobsFromJson(json);
  Map<String, dynamic> toJson() => _$CourseAiJobsToJson(this);
}

/// quizScores arrives as the JSON text stored in the progress row
Map<String, int>? _quizScoresFromJson(dynamic json) {
  if (json == null) return null;
  final map = json is String ? jsonDecode(json) : json;
  if (map is! Map) return null;
  return map.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
}

/// One slide of a module presentation; [notes] is the spoken narration
@JsonSerializable()
class CourseSlide {
  final String title;
  final List<String> bullets;
  final String? notes;

  CourseSlide({required this.title, this.bullets = const [], this.notes});

  factory CourseSlide.fromJson(Map<String, dynamic> json) =>
      _$CourseSlideFromJson(json);
  Map<String, dynamic> toJson() => _$CourseSlideToJson(this);
}

/// Multiple choice question of a module quiz. [correctIndex] and
/// [explanation] are only filled for authors.
@JsonSerializable()
class CourseQuizQuestion {
  final String? questionId;
  final String? moduleId;
  final int? sequenceNum;
  final String question;
  final List<String> options;
  final int? correctIndex;
  final String? explanation;

  CourseQuizQuestion({
    this.questionId,
    this.moduleId,
    this.sequenceNum,
    required this.question,
    this.options = const [],
    this.correctIndex,
    this.explanation,
  });

  factory CourseQuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$CourseQuizQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$CourseQuizQuestionToJson(this);
}

/// Questions of one module quiz, as a learner receives them
@JsonSerializable()
class CourseQuiz {
  final List<CourseQuizQuestion> questions;

  CourseQuiz({required this.questions});

  factory CourseQuiz.fromJson(Map<String, dynamic> json) =>
      _$CourseQuizFromJson(json);
  Map<String, dynamic> toJson() => _$CourseQuizToJson(this);
}

/// Outcome of one answered question
@JsonSerializable()
class CourseQuizAnswerResult {
  final String? questionId;
  final bool correct;
  final int? correctIndex;
  final String? explanation;

  CourseQuizAnswerResult({
    this.questionId,
    this.correct = false,
    this.correctIndex,
    this.explanation,
  });

  factory CourseQuizAnswerResult.fromJson(Map<String, dynamic> json) =>
      _$CourseQuizAnswerResultFromJson(json);
  Map<String, dynamic> toJson() => _$CourseQuizAnswerResultToJson(this);
}

/// Score of a submitted module quiz
@JsonSerializable()
class CourseQuizResult {
  final int scorePercent;
  final bool passed;
  final List<CourseQuizAnswerResult> results;

  CourseQuizResult({
    this.scorePercent = 0,
    this.passed = false,
    this.results = const [],
  });

  factory CourseQuizResult.fromJson(Map<String, dynamic> json) =>
      _$CourseQuizResultFromJson(json);
  Map<String, dynamic> toJson() => _$CourseQuizResultToJson(this);
}

/// Completion certificate data; the app renders the pdf.
@JsonSerializable()
class CourseCertificate {
  final bool eligible;

  /// Why not eligible yet
  final String? reason;
  final String? courseId;
  final String? courseTitle;
  final int? estimatedDuration;
  final String? learnerName;
  final String? companyName;
  @NullableTimestampConverter()
  final DateTime? completedDate;
  final String? certificateNo;

  CourseCertificate({
    this.eligible = false,
    this.reason,
    this.courseId,
    this.courseTitle,
    this.estimatedDuration,
    this.learnerName,
    this.companyName,
    this.completedDate,
    this.certificateNo,
  });

  factory CourseCertificate.fromJson(Map<String, dynamic> json) =>
      _$CourseCertificateFromJson(json);
  Map<String, dynamic> toJson() => _$CourseCertificateToJson(this);
}
