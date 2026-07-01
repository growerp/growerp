import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'master_content_event.dart';
import 'master_content_state.dart';

const _masterContentSearchDebounceDuration = Duration(milliseconds: 300);
EventTransformer<MasterContentSearchRequested> masterContentSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_masterContentSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

/// BLoC for managing platform-neutral Master Content pieces.
///
/// Calls the same REST services the ADK marketing agent uses, so menu and
/// agent are two front-ends over one tool layer.
class MasterContentBloc
    extends Bloc<MasterContentEvent, MasterContentState> {
  final RestClient restClient;

  MasterContentBloc(this.restClient) : super(const MasterContentState()) {
    on<MasterContentFetch>(_onFetch);
    on<MasterContentCreate>(_onCreate);
    on<MasterContentUpdate>(_onUpdate);
    on<MasterContentDelete>(_onDelete);
    on<MasterContentGenerateWithAI>(_onGenerateWithAI);
    on<MasterContentAdaptForPlatform>(_onAdaptForPlatform);
    on<MasterContentSearchRequested>(
      _onSearchRequested,
      transformer: masterContentSearchDebounce(),
    );
  }

  Future<void> _onFetch(
    MasterContentFetch event,
    Emitter<MasterContentState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;
    try {
      if (event.refresh || state.status == MasterContentStatus.initial) {
        emit(state.copyWith(status: MasterContentStatus.loading));
        final result = await restClient.getMasterContents(
          start: event.start,
          limit: event.limit,
          searchString: event.searchString,
          planId: event.planId,
        );
        emit(state.copyWith(
          status: MasterContentStatus.success,
          masterContents: result.masterContents,
          hasReachedMax: result.masterContents.length < event.limit,
        ));
      } else {
        final result = await restClient.getMasterContents(
          start: state.masterContents.length,
          limit: event.limit,
          searchString: event.searchString,
          planId: event.planId,
        );
        emit(state.copyWith(
          status: MasterContentStatus.success,
          masterContents: List.of(state.masterContents)
            ..addAll(result.masterContents),
          hasReachedMax: result.masterContents.length < event.limit,
        ));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: await getDioError(e)));
    } catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onCreate(
    MasterContentCreate event,
    Emitter<MasterContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MasterContentStatus.loading));
      final created = await restClient.createMasterContent(
        pseudoId: event.masterContent.pseudoId,
        planId: event.masterContent.planId,
        contentType: event.masterContent.contentType,
        pnpType: event.masterContent.pnpType,
        title: event.masterContent.title,
        body: event.masterContent.body,
        callToAction: event.masterContent.callToAction,
        targetUrl: event.masterContent.targetUrl,
        status: event.masterContent.status,
      );
      emit(state.copyWith(
        status: MasterContentStatus.success,
        masterContents: List<MasterContent>.from(state.masterContents)
          ..insert(0, created),
        message: 'Master content created successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: await getDioError(e)));
    } catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onUpdate(
    MasterContentUpdate event,
    Emitter<MasterContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MasterContentStatus.loading));
      final updated = await restClient.updateMasterContent(
        masterContentId: event.masterContent.masterContentId!,
        pseudoId: event.masterContent.pseudoId,
        planId: event.masterContent.planId,
        contentType: event.masterContent.contentType,
        pnpType: event.masterContent.pnpType,
        title: event.masterContent.title,
        body: event.masterContent.body,
        callToAction: event.masterContent.callToAction,
        targetUrl: event.masterContent.targetUrl,
        status: event.masterContent.status,
      );
      emit(state.copyWith(
        status: MasterContentStatus.success,
        masterContents: state.masterContents
            .map((m) => m.masterContentId == updated.masterContentId
                ? updated
                : m)
            .toList(),
        message: 'Master content updated successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: await getDioError(e)));
    } catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onDelete(
    MasterContentDelete event,
    Emitter<MasterContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MasterContentStatus.loading));
      await restClient.deleteMasterContent(
          masterContentId: event.masterContent.masterContentId!);
      emit(state.copyWith(
        status: MasterContentStatus.success,
        masterContents: state.masterContents
            .where((m) =>
                m.masterContentId != event.masterContent.masterContentId)
            .toList(),
        message: 'Master content deleted successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: await getDioError(e)));
    } catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onGenerateWithAI(
    MasterContentGenerateWithAI event,
    Emitter<MasterContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MasterContentStatus.loading));
      final created = await restClient.generateMasterContentWithAI(
        personaId: event.personaId,
        planId: event.planId,
        contentType: event.contentType,
        pnpType: event.pnpType,
        title: event.title,
        brief: event.brief,
        targetUrl: event.targetUrl,
      );
      emit(state.copyWith(
        status: MasterContentStatus.success,
        masterContents: List<MasterContent>.from(state.masterContents)
          ..insert(0, created),
        message: 'Master content generated successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: await getDioError(e)));
    } catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onAdaptForPlatform(
    MasterContentAdaptForPlatform event,
    Emitter<MasterContentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MasterContentStatus.loading));
      final raw = await restClient.adaptContentForPlatform(
        masterContentId: event.masterContentId,
        platforms: event.platforms,
        campaignId: event.campaignId,
        scheduledDate: event.scheduledDate?.millisecondsSinceEpoch,
      );
      // dio may return the body as a raw JSON String; decode defensively
      final result = (raw is String ? jsonDecode(raw) : raw)
          as Map<String, dynamic>;
      final count = result['adaptedCount'] ?? 0;
      emit(state.copyWith(
        status: MasterContentStatus.success,
        adaptResults: result,
        message: 'Adapted to $count platform(s)',
      ));
      // refresh so the ADAPTED status shows
      add(const MasterContentFetch(refresh: true));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: await getDioError(e)));
    } catch (e) {
      emit(state.copyWith(
          status: MasterContentStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onSearchRequested(
    MasterContentSearchRequested event,
    Emitter<MasterContentState> emit,
  ) async {
    return _onFetch(
      MasterContentFetch(refresh: true, searchString: event.searchString),
      emit,
    );
  }
}
