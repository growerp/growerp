import 'package:growerp_models/growerp_models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_post_model.g.dart';

/// Social Post model representing a single social media post
///
/// Supports dual-ID strategy:
/// - postId: System-wide unique identifier
/// - pseudoId: Tenant-unique, user-facing identifier
@JsonSerializable(explicitToJson: true)
class SocialPost {
  /// System-wide unique identifier
  final String? postId;

  /// Tenant-unique identifier (user-facing)
  final String? pseudoId;

  /// Associated content plan ID
  final String? planId;

  /// Post type: PAIN, NEWS, or PRIZE
  @JsonKey(defaultValue: 'PAIN')
  final String type;

  /// Platform: LINKEDIN, TWITTER, FACEBOOK
  final String? platform;

  /// Post headline
  final String? headline;

  /// Draft content (AI-generated or manually written)
  final String? draftContent;

  /// Final published content
  final String? finalContent;

  /// Post status: DRAFT, READY, PUBLISHED
  @JsonKey(defaultValue: 'DRAFT')
  final String status;

  /// Scheduled publish date
  @NullableTimestampConverter()
  final DateTime? scheduledDate;

  /// Actual publish date
  @NullableTimestampConverter()
  final DateTime? publishedDate;

  /// Timestamp when created
  @NullableTimestampConverter()
  final DateTime? createdDate;

  /// Timestamp when last modified
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  const SocialPost({
    this.postId,
    this.pseudoId,
    this.planId,
    required this.type,
    this.platform,
    this.headline,
    this.draftContent,
    this.finalContent,
    required this.status,
    this.scheduledDate,
    this.publishedDate,
    this.createdDate,
    this.lastModifiedDate,
  });

  /// Creates a copy of this social post with optionally replaced fields
  SocialPost copyWith({
    String? postId,
    String? pseudoId,
    String? planId,
    String? type,
    String? platform,
    String? headline,
    String? draftContent,
    String? finalContent,
    String? status,
    DateTime? scheduledDate,
    DateTime? publishedDate,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) {
    return SocialPost(
      postId: postId ?? this.postId,
      pseudoId: pseudoId ?? this.pseudoId,
      planId: planId ?? this.planId,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      headline: headline ?? this.headline,
      draftContent: draftContent ?? this.draftContent,
      finalContent: finalContent ?? this.finalContent,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      publishedDate: publishedDate ?? this.publishedDate,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  /// Converts JSON to SocialPost object
  factory SocialPost.fromJson(Map<String, dynamic> json) =>
      _$SocialPostFromJson(json['socialPost'] ?? json);

  /// Converts SocialPost object to JSON
  Map<String, dynamic> toJson() => _$SocialPostToJson(this);

  @override
  String toString() => 'SocialPost(id: $postId, type: $type, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialPost &&
          runtimeType == other.runtimeType &&
          postId == other.postId;

  @override
  int get hashCode => postId.hashCode;
}

/// List wrapper for SocialPost objects
@JsonSerializable()
class SocialPosts {
  final List<SocialPost> socialPosts;

  const SocialPosts({required this.socialPosts});

  factory SocialPosts.fromJson(Map<String, dynamic> json) =>
      _$SocialPostsFromJson(json);
  Map<String, dynamic> toJson() => _$SocialPostsToJson(this);
}
