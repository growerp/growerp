import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Status enum for ContentPlan operations
enum ContentPlanStatus {
  initial,
  loading,
  success,
  failure,
}

/// State class for ContentPlanBloc
class ContentPlanState extends Equatable {
  final ContentPlanStatus status;
  final List<ContentPlan> contentPlans;
  final String? message;
  final bool hasReachedMax;

  final List<ContentPlan> searchResults;
  final ContentPlanStatus searchStatus;
  final String? searchError;

  const ContentPlanState({
    this.status = ContentPlanStatus.initial,
    this.contentPlans = const [],
    this.message,
    this.hasReachedMax = false,
    this.searchResults = const [],
    this.searchStatus = ContentPlanStatus.initial,
    this.searchError,
  });

  ContentPlanState copyWith({
    ContentPlanStatus? status,
    List<ContentPlan>? contentPlans,
    String? message,
    bool? hasReachedMax,
    List<ContentPlan>? searchResults,
    ContentPlanStatus? searchStatus,
    String? searchError,
  }) {
    return ContentPlanState(
      status: status ?? this.status,
      contentPlans: contentPlans ?? this.contentPlans,
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
        contentPlans,
        message,
        hasReachedMax,
        searchResults,
        searchStatus,
        searchError,
      ];

  @override
  String toString() {
    return 'ContentPlanState { status: $status, hasReachedMax: $hasReachedMax, '
        'contentPlans: ${contentPlans.length}, message: $message, '
        'searchResults: ${searchResults.length}, searchStatus: $searchStatus }';
  }
}
