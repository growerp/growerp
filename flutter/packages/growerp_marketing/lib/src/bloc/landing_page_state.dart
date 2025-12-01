import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

enum LandingPageStatus { initial, loading, success, failure }

class LandingPageState extends Equatable {
  final LandingPageStatus status;
  final List<LandingPage> landingPages;
  final LandingPage? selectedLandingPage;
  final List<AssessmentQuestion>? questions;
  final List<CredibilityInfo>? credibility;
  final String? message;
  final bool hasReachedMax;
  final int start;
  final int limit;
  final List<LandingPage> searchResults;
  final LandingPageStatus searchStatus;
  final String? searchError;

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
    this.searchResults = const [],
    this.searchStatus = LandingPageStatus.initial,
    this.searchError,
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
    List<LandingPage>? searchResults,
    LandingPageStatus? searchStatus,
    String? searchError,
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
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      start: start ?? this.start,
      limit: limit ?? this.limit,
      searchResults: searchResults ?? this.searchResults,
      searchStatus: searchStatus ?? this.searchStatus,
      searchError: searchError ?? this.searchError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        landingPages,
        selectedLandingPage,
        questions,
        credibility,
        message,
        hasReachedMax,
        start,
        limit,
        searchResults,
        searchStatus,
        searchError,
      ];

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
        'searchResults: ${searchResults.length}, '
        'searchStatus: $searchStatus, '
        'searchError: $searchError'
        ')';
  }
}
