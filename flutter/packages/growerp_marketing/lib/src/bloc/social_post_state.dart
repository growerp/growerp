import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Status enum for SocialPost operations
enum SocialPostStatus {
  initial,
  loading,
  success,
  failure,
}

/// State class for SocialPostBloc
class SocialPostState extends Equatable {
  final SocialPostStatus status;
  final List<SocialPost> socialPosts;
  final String? message;
  final bool hasReachedMax;

  final List<SocialPost> searchResults;
  final SocialPostStatus searchStatus;
  final String? searchError;

  const SocialPostState({
    this.status = SocialPostStatus.initial,
    this.socialPosts = const [],
    this.message,
    this.hasReachedMax = false,
    this.searchResults = const [],
    this.searchStatus = SocialPostStatus.initial,
    this.searchError,
  });

  SocialPostState copyWith({
    SocialPostStatus? status,
    List<SocialPost>? socialPosts,
    String? message,
    bool? hasReachedMax,
    List<SocialPost>? searchResults,
    SocialPostStatus? searchStatus,
    String? searchError,
  }) {
    return SocialPostState(
      status: status ?? this.status,
      socialPosts: socialPosts ?? this.socialPosts,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchResults: searchResults ?? this.searchResults,
      searchStatus: searchStatus ?? this.searchStatus,
      searchError: searchError ?? this.searchError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        socialPosts,
        message,
        hasReachedMax,
        searchResults,
        searchStatus,
        searchError,
      ];

  @override
  String toString() {
    return 'SocialPostState { status: $status, hasReachedMax: $hasReachedMax, '
        'socialPosts: ${socialPosts.length}, message: $message, '
        'searchResults: ${searchResults.length}, searchStatus: $searchStatus }';
  }
}
