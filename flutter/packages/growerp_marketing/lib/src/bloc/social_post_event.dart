import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Base class for all SocialPost events
abstract class SocialPostEvent extends Equatable {
  const SocialPostEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch social posts (with optional refresh and search)
class SocialPostFetch extends SocialPostEvent {
  final bool refresh;
  final int limit;
  final int start;
  final String searchString;
  final String? planId;

  const SocialPostFetch({
    this.refresh = false,
    this.limit = 20,
    this.start = 0,
    this.searchString = '',
    this.planId,
  });

  @override
  List<Object?> get props => [refresh, limit, start, searchString, planId];
}

/// Event to create a new social post
class SocialPostCreate extends SocialPostEvent {
  final SocialPost socialPost;

  const SocialPostCreate(this.socialPost);

  @override
  List<Object?> get props => [socialPost];
}

/// Event to update an existing social post
class SocialPostUpdate extends SocialPostEvent {
  final SocialPost socialPost;

  const SocialPostUpdate(this.socialPost);

  @override
  List<Object?> get props => [socialPost];
}

/// Event to delete a social post
class SocialPostDelete extends SocialPostEvent {
  final SocialPost socialPost;

  const SocialPostDelete(this.socialPost);

  @override
  List<Object?> get props => [socialPost];
}

/// Event to draft a social post using AI
class SocialPostDraftWithAI extends SocialPostEvent {
  final String postId;

  const SocialPostDraftWithAI({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class SocialPostSearchRequested extends SocialPostEvent {
  final String searchString;

  const SocialPostSearchRequested({required this.searchString});

  @override
  List<Object> get props => [searchString];
}
