import 'package:growerp_models/growerp_models.dart';

enum LandingPageStatus { initial, loading, success, failure }

class LandingPageState {
  final LandingPageStatus status;
  final List<LandingPage> landingPages;
  final LandingPage? selectedLandingPage;
  final List<AssessmentQuestion>? questions;
  final List<CredibilityInfo>? credibility;
  final String? message;
  final bool hasReachedMax;
  final int start;
  final int limit;
  final String? searchString;

  const LandingPageState({
    this.status = LandingPageStatus.initial,
    this.landingPages = const [],
    this.selectedLandingPage,
    this.questions,
    this.credibility,
    this.message,
    this.hasReachedMax = false,
    this.start = 0,
    this.limit = 20,
    this.searchString,
  });

  LandingPageState copyWith({
    LandingPageStatus? status,
    List<LandingPage>? landingPages,
    LandingPage? selectedLandingPage,
    List<AssessmentQuestion>? questions,
    List<CredibilityInfo>? credibility,
    String? message,
    bool? hasReachedMax,
    int? start,
    int? limit,
    String? searchString,
    bool clearSelectedLandingPage = false,
  }) {
    return LandingPageState(
      status: status ?? this.status,
      landingPages: landingPages ?? this.landingPages,
      selectedLandingPage: clearSelectedLandingPage
          ? null
          : selectedLandingPage ?? this.selectedLandingPage,
      questions: questions ?? this.questions,
      credibility: credibility ?? this.credibility,
      message: message ?? this.message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      start: start ?? this.start,
      limit: limit ?? this.limit,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  String toString() {
    return 'LandingPageState('
        'status: $status, '
        'landingPages: ${landingPages.length}, '
        'selectedLandingPage: $selectedLandingPage, '
        'questions: ${questions?.length}, '
        'credibility: ${credibility?.length}, '
        'message: $message, '
        'hasReachedMax: $hasReachedMax, '
        'start: $start, '
        'limit: $limit, '
        'searchString: $searchString'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandingPageState &&
        other.status == status &&
        other.landingPages == landingPages &&
        other.selectedLandingPage == selectedLandingPage &&
        other.questions == questions &&
        other.credibility == credibility &&
        other.message == message &&
        other.hasReachedMax == hasReachedMax &&
        other.start == start &&
        other.limit == limit &&
        other.searchString == searchString;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        landingPages.hashCode ^
        selectedLandingPage.hashCode ^
        questions.hashCode ^
        credibility.hashCode ^
        message.hashCode ^
        hasReachedMax.hashCode ^
        start.hashCode ^
        limit.hashCode ^
        searchString.hashCode;
  }
}
