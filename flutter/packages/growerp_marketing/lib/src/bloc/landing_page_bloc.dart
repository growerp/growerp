import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'landing_page_event.dart';
import 'landing_page_state.dart';

class LandingPageBloc extends Bloc<LandingPageEvent, LandingPageState> {
  final RestClient restClient;
  final String classificationId;

  LandingPageBloc({required this.restClient, required this.classificationId})
    : super(const LandingPageState()) {
    on<LandingPageLoad>(_onLandingPageLoad);
    on<LandingPageFetch>(_onLandingPageFetch);
    on<LandingPageCreate>(_onLandingPageCreate);
    on<LandingPageUpdate>(_onLandingPageUpdate);
    on<LandingPageDelete>(_onLandingPageDelete);
    on<LandingPageClear>(_onLandingPageClear);
    on<LandingPageSearchRequested>(_onLandingPageSearch);
  }

  // get a single or a list of landingpages
  Future<void> _onLandingPageLoad(
    LandingPageLoad event,
    Emitter<LandingPageState> emit,
  ) async {
    if (state.hasReachedMax && event.start > 0) return;

    try {
      if (event.start == 0) {
        emit(
          state.copyWith(
            status: LandingPageStatus.loading,
            landingPages: [],
            hasReachedMax: false,
          ),
        );
      }

      final result = await restClient.getLandingPages(
        start: event.start,
        limit: event.limit,
        searchString: event.searchString.isNotEmpty ? event.searchString : null,
      );

      final landingPages = event.start == 0
          ? List<LandingPage>.from(result.landingPages)
          : (List<LandingPage>.from(state.landingPages)
              ..addAll(result.landingPages));

      emit(
        state.copyWith(
          status: LandingPageStatus.success,
          landingPages: landingPages,
          hasReachedMax: result.landingPages.length < event.limit,
          start: event.start,
          limit: event.limit,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LandingPageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onLandingPageSearch(
    LandingPageSearchRequested event,
    Emitter<LandingPageState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          searchStatus: LandingPageStatus.success,
          searchResults: const [],
          searchError: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        searchStatus: LandingPageStatus.loading,
        searchResults: const [],
        searchError: null,
      ),
    );

    try {
      final result = await restClient.getLandingPages(
        start: 0,
        limit: event.limit,
        searchString: query,
      );

      emit(
        state.copyWith(
          searchStatus: LandingPageStatus.success,
          searchResults: result.landingPages,
          searchError: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          searchStatus: LandingPageStatus.failure,
          searchResults: const [],
          searchError: await getDioError(error),
        ),
      );
    }
  }

  // Fetch a single landing page by ID/pseudoId and related data
  Future<void> _onLandingPageFetch(
    LandingPageFetch event,
    Emitter<LandingPageState> emit,
  ) async {
    emit(state.copyWith(status: LandingPageStatus.loading));
    try {
      final landingPage = await restClient.getLandingPage(
        landingPageId: event.landingPageId,
        pseudoId: event.pseudoId,
        ownerPartyId: event.ownerPartyId,
      );
      emit(
        state.copyWith(
          status: LandingPageStatus.success,
          selectedLandingPage: landingPage,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LandingPageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onLandingPageCreate(
    LandingPageCreate event,
    Emitter<LandingPageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LandingPageStatus.loading));

      final newLandingPage = await restClient.createLandingPage(
        title: event.landingPage.title,
        pseudoId: event.landingPage.pseudoId,
        headline: event.landingPage.headline,
        subheading: event.landingPage.subheading,
        hookType: event.landingPage.hookType,
        status: event.landingPage.status,
        privacyPolicyUrl: event.landingPage.privacyPolicyUrl,
        ctaActionType: event.landingPage.ctaActionType,
        ctaAssessmentId: event.landingPage.ctaAssessmentId,
        ctaButtonLink: event.landingPage.ctaButtonLink,
      );

      final updatedLandingPages = List<LandingPage>.from(state.landingPages)
        ..insert(0, newLandingPage);

      emit(
        state.copyWith(
          status: LandingPageStatus.success,
          landingPages: updatedLandingPages,
          selectedLandingPage: newLandingPage,
          message: 'Landing page created successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LandingPageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onLandingPageUpdate(
    LandingPageUpdate event,
    Emitter<LandingPageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LandingPageStatus.loading));

      final updatedLandingPage = await restClient.updateLandingPage(
        landingPageId: event.landingPage.landingPageId ?? '',
        pseudoId: event.landingPage.pseudoId,
        title: event.landingPage.title,
        headline: event.landingPage.headline,
        subheading: event.landingPage.subheading,
        hookType: event.landingPage.hookType,
        status: event.landingPage.status,
        privacyPolicyUrl: event.landingPage.privacyPolicyUrl,
        ctaActionType: event.landingPage.ctaActionType,
        ctaAssessmentId: event.landingPage.ctaAssessmentId,
        ctaButtonLink: event.landingPage.ctaButtonLink,
      );

      final updatedLandingPages = state.landingPages
          .map<LandingPage>(
            (page) =>
                (page.landingPageId ?? '') ==
                    (updatedLandingPage.landingPageId ?? '')
                ? updatedLandingPage
                : page,
          )
          .toList();

      emit(
        state.copyWith(
          status: LandingPageStatus.success,
          landingPages: updatedLandingPages,
          selectedLandingPage: updatedLandingPage,
          message: 'Landing page updated successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LandingPageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onLandingPageDelete(
    LandingPageDelete event,
    Emitter<LandingPageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LandingPageStatus.loading));

      await restClient.deleteLandingPage(landingPageId: event.landingPageId);

      final updatedLandingPages = state.landingPages
          .where((page) => (page.landingPageId ?? '') != event.landingPageId)
          .toList();

      emit(
        state.copyWith(
          status: LandingPageStatus.success,
          landingPages: updatedLandingPages,
          message: 'Landing page deleted successfully',
          clearSelectedLandingPage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LandingPageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onLandingPageClear(
    LandingPageClear event,
    Emitter<LandingPageState> emit,
  ) async {
    emit(state.copyWith(clearSelectedLandingPage: true));
  }
}
