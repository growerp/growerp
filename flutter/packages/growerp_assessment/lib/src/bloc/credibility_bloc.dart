import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'credibility_event.dart';
import 'credibility_state.dart';

class CredibilityBloc extends Bloc<CredibilityEvent, CredibilityState> {
  CredibilityBloc() : super(const CredibilityState()) {
    on<CredibilityLoad>(_onCredibilityLoad);
    on<CredibilityInfoCreate>(_onCredibilityInfoCreate);
    on<CredibilityInfoUpdate>(_onCredibilityInfoUpdate);
    on<CredibilityInfoDelete>(_onCredibilityInfoDelete);
    on<CredibilityStatisticCreate>(_onCredibilityStatisticCreate);
    on<CredibilityStatisticUpdate>(_onCredibilityStatisticUpdate);
    on<CredibilityStatisticDelete>(_onCredibilityStatisticDelete);
    on<CredibilityReorder>(_onCredibilityReorder);
  }

  Future<void> _onCredibilityLoad(
    CredibilityLoad event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      // For now, just emit an empty state as credibility elements
      // will be loaded as part of the landing page data
      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: const [],
        credibilityStatistics: const [],
        message: 'Credibility data loaded successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: 'Failed to load credibility data: ${error.toString()}',
      ));
    }
  }

  Future<void> _onCredibilityInfoCreate(
    CredibilityInfoCreate event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      final restClient = RestClient(await buildDioClient());

      final newCredibilityElement = await restClient.createCredibilityInfo(
        pageId: event.pageId,
        creatorBio: event.infoTitle, // Using title as bio for now
        backgroundText: event.infoDescription,
        creatorImageUrl: event.infoIconName, // Using icon as image URL
      );

      final updatedElements =
          List<CredibilityElement>.from(state.credibilityElements)
            ..add(newCredibilityElement);

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: updatedElements,
        message: 'Credibility element created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: 'Failed to create credibility element: ${error.toString()}',
      ));
    }
  }

  Future<void> _onCredibilityInfoUpdate(
    CredibilityInfoUpdate event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      final restClient = RestClient(await buildDioClient());

      final updatedCredibilityElement = await restClient.updateCredibilityInfo(
        pageId: event.pageId, // Add pageId parameter
        credibilityId: event.infoId,
        creatorBio: event.infoTitle, // Using title as bio for now
        backgroundText: event.infoDescription,
        creatorImageUrl: event.infoIconName, // Using icon as image URL
      );

      final updatedElements = state.credibilityElements.map((element) {
        if (element.credibilityId == event.infoId) {
          return updatedCredibilityElement;
        }
        return element;
      }).toList();

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: updatedElements,
        message: 'Credibility element updated successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: 'Failed to update credibility element: ${error.toString()}',
      ));
    }
  }

  Future<void> _onCredibilityInfoDelete(
    CredibilityInfoDelete event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      final restClient = RestClient(await buildDioClient());

      await restClient.deleteCredibilityInfo(
        pageId: event.pageId,
        credibilityId: event.infoId,
      );

      final updatedElements = state.credibilityElements
          .where((element) => element.credibilityId != event.infoId)
          .toList();

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: updatedElements,
        message: 'Credibility element deleted successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: 'Failed to delete credibility element: ${error.toString()}',
      ));
    }
  }

  Future<void> _onCredibilityStatisticCreate(
    CredibilityStatisticCreate event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      // We need a credibilityId to create statistics, so get the first one or fail gracefully
      if (state.credibilityElements.isEmpty) {
        emit(state.copyWith(
          status: CredibilityStatus.failure,
          message:
              'Please create a credibility element first before adding statistics',
        ));
        return;
      }

      final restClient = RestClient(await buildDioClient());
      final credibilityId = state.credibilityElements.first.credibilityId ?? '';

      final newStatistic = await restClient.addCredibilityStatistic(
        credibilityId: credibilityId,
        statistic:
            '${event.statLabel}: ${event.statValue}', // Combine label and value
      );

      final updatedStatistics =
          List<Map<String, dynamic>>.from(state.credibilityStatistics)
            ..add(newStatistic as Map<String, dynamic>);

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityStatistics: updatedStatistics,
        message: 'Credibility statistic created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: 'Failed to create credibility statistic: ${error.toString()}',
      ));
    }
  }

  Future<void> _onCredibilityStatisticUpdate(
    CredibilityStatisticUpdate event,
    Emitter<CredibilityState> emit,
  ) async {
    // Note: The REST API doesn't have an update endpoint for statistics,
    // so we'll need to delete and recreate
    emit(state.copyWith(
      status: CredibilityStatus.failure,
      message: 'Statistic update not supported - please delete and recreate',
    ));
  }

  Future<void> _onCredibilityStatisticDelete(
    CredibilityStatisticDelete event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      final restClient = RestClient(await buildDioClient());

      await restClient.removeCredibilityStatistic(
        statisticId: event.statisticId,
      );

      final updatedStatistics = state.credibilityStatistics
          .where((stat) => stat['statisticId'] != event.statisticId)
          .toList();

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityStatistics: updatedStatistics,
        message: 'Credibility statistic deleted successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: 'Failed to delete credibility statistic: ${error.toString()}',
      ));
    }
  }

  Future<void> _onCredibilityReorder(
    CredibilityReorder event,
    Emitter<CredibilityState> emit,
  ) async {
    // Reorder credibility elements based on new order
    final reorderedElements = <CredibilityElement>[];

    for (final credibilityId in event.newInfoOrder) {
      final element = state.credibilityElements.firstWhere(
        (element) => element.credibilityId == credibilityId,
      );
      reorderedElements.add(element);
    }

    emit(state.copyWith(
      credibilityElements: reorderedElements,
      message: 'Credibility elements reordered',
    ));
  }
}
