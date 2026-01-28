/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:json_annotation/json_annotation.dart';
import '../json_converters.dart';

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
  final String title;
  final String? description;
  final String? objectives;
  final String? targetPersonaId;
  final CourseDifficulty? difficulty;
  final int? estimatedDuration;
  final CourseStatus? status;
  final String? coverImageUrl;
  @DateTimeConverter()
  final DateTime? createdDate;
  @DateTimeConverter()
  final DateTime? lastModifiedDate;
  final List<CourseModule>? modules;

  /// Count of modules (from view entity for list display)
  final int? moduleCount;

  /// Count of lessons (from view entity for list display)
  final int? lessonCount;

  Course({
    this.courseId,
    this.pseudoId,
    this.ownerPartyId,
    required this.title,
    this.description,
    this.objectives,
    this.targetPersonaId,
    this.difficulty = CourseDifficulty.beginner,
    this.estimatedDuration,
    this.status = CourseStatus.draft,
    this.coverImageUrl,
    this.createdDate,
    this.lastModifiedDate,
    this.modules,
    this.moduleCount,
    this.lessonCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  Course copyWith({
    String? courseId,
    String? pseudoId,
    String? ownerPartyId,
    String? title,
    String? description,
    String? objectives,
    String? targetPersonaId,
    CourseDifficulty? difficulty,
    int? estimatedDuration,
    CourseStatus? status,
    String? coverImageUrl,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    List<CourseModule>? modules,
    int? moduleCount,
    int? lessonCount,
  }) => Course(
    courseId: courseId ?? this.courseId,
    pseudoId: pseudoId ?? this.pseudoId,
    ownerPartyId: ownerPartyId ?? this.ownerPartyId,
    title: title ?? this.title,
    description: description ?? this.description,
    objectives: objectives ?? this.objectives,
    targetPersonaId: targetPersonaId ?? this.targetPersonaId,
    difficulty: difficulty ?? this.difficulty,
    estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    status: status ?? this.status,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    createdDate: createdDate ?? this.createdDate,
    lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    modules: modules ?? this.modules,
    moduleCount: moduleCount ?? this.moduleCount,
    lessonCount: lessonCount ?? this.lessonCount,
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
  @DateTimeConverter()
  final DateTime? createdDate;
  @DateTimeConverter()
  final DateTime? lastModifiedDate;
  final List<CourseLesson>? lessons;

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
  @DateTimeConverter()
  final DateTime? createdDate;
  @DateTimeConverter()
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
  @DateTimeConverter()
  final DateTime? scheduledDate;
  @DateTimeConverter()
  final DateTime? publishedDate;
  @DateTimeConverter()
  final DateTime? createdDate;
  @DateTimeConverter()
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
  @DateTimeConverter()
  final DateTime? startedDate;
  @DateTimeConverter()
  final DateTime? lastAccessDate;
  @DateTimeConverter()
  final DateTime? completedDate;

  CourseProgress({
    this.progressId,
    this.userId,
    this.courseId,
    this.currentLessonId,
    this.completedLessons,
    this.progressPercent = 0,
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

  CourseProgress copyWith({
    String? progressId,
    String? userId,
    String? courseId,
    String? currentLessonId,
    List<String>? completedLessons,
    int? progressPercent,
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
    startedDate: startedDate ?? this.startedDate,
    lastAccessDate: lastAccessDate ?? this.lastAccessDate,
    completedDate: completedDate ?? this.completedDate,
  );

  @override
  String toString() => 'CourseProgress($courseId - $progressPercent%)';
}
