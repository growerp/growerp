import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'content_plan_event.dart';
import 'content_plan_state.dart';

const _contentPlanSearchDebounceDuration = Duration(milliseconds: 300);
EventTransformer<ContentPlanSearchRequested> contentPlanSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_contentPlanSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

/// BLoC for managing Content Plans
class ContentPlanBloc extends Bloc<ContentPlanEvent, ContentPlanState> {
  final RestClient restClient;

  ContentPlanBloc(this.restClient) : super(const ContentPlanState()) {
    on<ContentPlanFetch>(_onContentPlanFetch);
    on<ContentPlanCreate>(_onContentPlanCreate);
    on<ContentPlanUpdate>(_onContentPlanUpdate);
    on<ContentPlanDelete>(_onContentPlanDelete);
    on<ContentPlanGenerateWithAI>(_onContentPlanGenerateWithAI);
    on<ContentPlanSearchRequested>(
      _onContentPlanSearchRequested,
      transformer: contentPlanSearchDebounce(),
    );
  }

  Future<void> _onContentPlanFetch(
    ContentPlanFetch event,
    Emitter<ContentPlanState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;

    try {
      if (event.refresh || state.status == ContentPlanStatus.initial) {
        emit(state.copyWith(status: ContentPlanStatus.loading));

        final result = await restClient.getContentPlans(
          start: event.start,
          limit: event.limit,
          searchString: event.searchString,
        );

        final contentPlans = result.contentPlans;

        emit(
          state.copyWith(
            status: ContentPlanStatus.success,
            contentPlans: contentPlans,
            hasReachedMax: contentPlans.length < event.limit,
          ),
        );
      } else {
        final result = await restClient.getContentPlans(
          start: state.contentPlans.length,
          limit: event.limit,
          searchString: event.searchString,
        );

        final contentPlans = result.contentPlans;

        emit(
          state.copyWith(
            status: ContentPlanStatus.success,
            contentPlans: List.of(state.contentPlans)..addAll(contentPlans),
            hasReachedMax: contentPlans.length < event.limit,
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onContentPlanCreate(
    ContentPlanCreate event,
    Emitter<ContentPlanState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ContentPlanStatus.loading));

      final newContentPlan = await restClient.createContentPlan(
        pseudoId: event.contentPlan.pseudoId,
        personaId: event.contentPlan.personaId,
        weekStartDate: event.contentPlan.weekStartDate?.millisecondsSinceEpoch,
        theme: event.contentPlan.theme,
      );

      final updatedContentPlans = List<ContentPlan>.from(state.contentPlans)
        ..insert(0, newContentPlan);

      emit(
        state.copyWith(
          status: ContentPlanStatus.success,
          contentPlans: updatedContentPlans,
          message: 'Content plan created successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onContentPlanUpdate(
    ContentPlanUpdate event,
    Emitter<ContentPlanState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ContentPlanStatus.loading));

      final updatedContentPlan = await restClient.updateContentPlan(
        planId: event.contentPlan.planId!,
        pseudoId: event.contentPlan.pseudoId,
        personaId: event.contentPlan.personaId,
        weekStartDate: event.contentPlan.weekStartDate?.millisecondsSinceEpoch,
        theme: event.contentPlan.theme,
      );

      final updatedContentPlans = state.contentPlans
          .map(
            (p) =>
                p.planId == event.contentPlan.planId ? updatedContentPlan : p,
          )
          .toList();

      emit(
        state.copyWith(
          status: ContentPlanStatus.success,
          contentPlans: updatedContentPlans,
          message: 'Content plan updated successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onContentPlanDelete(
    ContentPlanDelete event,
    Emitter<ContentPlanState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ContentPlanStatus.loading));

      await restClient.deleteContentPlan(planId: event.contentPlan.planId!);

      final updatedContentPlans = state.contentPlans
          .where((p) => p.planId != event.contentPlan.planId)
          .toList();

      emit(
        state.copyWith(
          status: ContentPlanStatus.success,
          contentPlans: updatedContentPlans,
          message: 'Content plan deleted successfully',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onContentPlanGenerateWithAI(
    ContentPlanGenerateWithAI event,
    Emitter<ContentPlanState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ContentPlanStatus.loading));

      final generatedContentPlan = await restClient.generateContentPlanWithAI(
        personaId: event.personaId,
        weekStartDate: event.weekStartDate?.millisecondsSinceEpoch,
      );

      final updatedContentPlans = List<ContentPlan>.from(state.contentPlans)
        ..insert(0, generatedContentPlan);

      emit(
        state.copyWith(
          status: ContentPlanStatus.success,
          contentPlans: updatedContentPlans,
          message: 'Content plan generated successfully with AI',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: await getDioError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ContentPlanStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onContentPlanSearchRequested(
    ContentPlanSearchRequested event,
    Emitter<ContentPlanState> emit,
  ) async {
    return _onContentPlanFetch(
      ContentPlanFetch(refresh: true, searchString: event.searchString),
      emit,
    );
  }
}
