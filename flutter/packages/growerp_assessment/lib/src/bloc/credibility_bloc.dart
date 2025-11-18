import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'credibility_event.dart';
import 'credibility_state.dart';

class CredibilityBloc extends Bloc<CredibilityEvent, CredibilityState> {
  final RestClient restClient;

  CredibilityBloc({required this.restClient})
      : super(const CredibilityState()) {
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
      final response = await restClient.getCredibilityInfo(
        landingPageId: event.landingPageId,
      );

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: response.credibilityInfoList,
        message: 'Credibility data loaded successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onCredibilityInfoCreate(
    CredibilityInfoCreate event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      final newCredibilityElement = await restClient.createCredibilityInfo(
        landingPageId: event.landingPageId,
        creatorBio: event.infoTitle, // Using title as bio for now
        backgroundText: event.infoDescription,
        creatorImageUrl: event.infoIconName, // Using icon as image URL
      );

      final updatedElements =
          List<CredibilityInfo>.from(state.credibilityElements)
            ..add(newCredibilityElement);

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: updatedElements,
        message: 'Credibility element created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onCredibilityInfoUpdate(
    CredibilityInfoUpdate event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      final updatedCredibilityInfo = await restClient.updateCredibilityInfo(
        landingPageId: event.landingPageId,
        credibilityInfoId: event.credibilityInfoId,
        creatorBio: event.infoTitle,
        backgroundText: event.infoDescription,
        creatorImageUrl: event.infoIconName,
      );

      final updatedElements = state.credibilityElements.map((element) {
        if ((element.credibilityInfoId ?? '') == event.credibilityInfoId) {
          return updatedCredibilityInfo;
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
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onCredibilityInfoDelete(
    CredibilityInfoDelete event,
    Emitter<CredibilityState> emit,
  ) async {
    emit(state.copyWith(status: CredibilityStatus.loading));

    try {
      await restClient.deleteCredibilityInfo(
        landingPageId: event.landingPageId,
        credibilityInfoId: event.credibilityInfoId,
      );

      final updatedElements = state.credibilityElements.where((element) {
        final elementId = element.credibilityInfoId ?? '';
        return elementId != event.credibilityInfoId;
      }).toList();

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: updatedElements,
        message: 'Credibility element deleted successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: await getDioError(error),
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

      final credibilityId =
          state.credibilityElements.first.credibilityInfoId ?? '';

      final newStatistic = await restClient.addCredibilityStatistic(
        credibilityId: credibilityId,
        statistic:
            '${event.statLabel}: ${event.statValue}', // Combine label and value
      );

      // Convert the response to CredibilityStatistic
      final statisticObj = CredibilityStatistic.fromJson(newStatistic);

      // Update the credibilityElements list with the new statistic
      final updatedElements = state.credibilityElements.map((credInfo) {
        if (credInfo.credibilityInfoId == credibilityId) {
          // Create a new CredibilityInfo with the updated statistics list
          final currentStats = credInfo.statistics ?? [];
          final newStats = [...currentStats, statisticObj];
          return CredibilityInfo(
            credibilityInfoId: credInfo.credibilityInfoId,
            pseudoId: credInfo.pseudoId,
            creatorBio: credInfo.creatorBio,
            backgroundText: credInfo.backgroundText,
            creatorImageUrl: credInfo.creatorImageUrl,
            statistics: newStats,
          );
        }
        return credInfo;
      }).toList();

      final updatedStatistics =
          List<Map<String, dynamic>>.from(state.credibilityStatistics)
            ..add(newStatistic as Map<String, dynamic>);

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityElements: updatedElements,
        credibilityStatistics: updatedStatistics,
        message: 'Credibility statistic created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: await getDioError(error),
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
      await restClient.removeCredibilityStatistic(
        credibilityStatisticId: event.credibilityStatisticId,
      );

      final updatedStatistics = state.credibilityStatistics
          .where((stat) =>
              stat['credibilityStatisticId'] != event.credibilityStatisticId)
          .toList();

      emit(state.copyWith(
        status: CredibilityStatus.success,
        credibilityStatistics: updatedStatistics,
        message: 'Credibility statistic deleted successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CredibilityStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onCredibilityReorder(
    CredibilityReorder event,
    Emitter<CredibilityState> emit,
  ) async {
    // Reorder credibility elements based on new order
    final reorderedElements = <CredibilityInfo>[];

    for (final credibilityId in event.newInfoOrder) {
      final element = state.credibilityElements.firstWhere(
        (element) => (element.credibilityInfoId ?? '') == credibilityId,
      );
      reorderedElements.add(element);
    }

    emit(state.copyWith(
      credibilityElements: reorderedElements,
      message: 'Credibility elements reordered',
    ));
  }
}
