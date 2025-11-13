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
        searchString,
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
        'searchString: $searchString'
        ')';
  }
}
