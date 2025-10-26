import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'cta_event.dart';
import 'cta_state.dart';

class CTABloc extends Bloc<CTAEvent, CTAState> {
  CTABloc() : super(const CTAState()) {
    on<CTALoad>(_onLoad);
    on<CTACreate>(_onCreate);
    on<CTAUpdate>(_onUpdate);
    on<CTADelete>(_onDelete);
  }

  Future<void> _onLoad(
    CTALoad event,
    Emitter<CTAState> emit,
  ) async {
    // Note: No GET endpoint available for CTA, so just set initial state
    emit(state.copyWith(
      status: CTAStatus.success,
      callToAction: null,
      message: 'CTA state initialized',
    ));
  }

  Future<void> _onCreate(
    CTACreate event,
    Emitter<CTAState> emit,
  ) async {
    emit(state.copyWith(status: CTAStatus.loading));

    try {
      final restClient = RestClient(await buildDioClient());

      final newCallToAction = await restClient.createPrimaryCTA(
        pageId: event.pageId,
        buttonText: event.buttonText,
        estimatedTime:
            event.actionTarget, // Map actionTarget to estimatedTime for now
        cost: event.buttonStyle, // Map buttonStyle to cost for now
        valuePromise:
            event.actionType, // Map actionType to valuePromise for now
      );

      emit(state.copyWith(
        status: CTAStatus.success,
        callToAction: newCallToAction,
        message: 'CTA created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CTAStatus.failure,
        message: 'Failed to create CTA: ${error.toString()}',
      ));
    }
  }

  Future<void> _onUpdate(
    CTAUpdate event,
    Emitter<CTAState> emit,
  ) async {
    emit(state.copyWith(status: CTAStatus.loading));

    try {
      final restClient = RestClient(await buildDioClient());

      final updatedCallToAction = await restClient.updatePrimaryCTA(
        pageId: event.pageId,
        ctaId: event.ctaId,
        buttonText: event.buttonText,
        estimatedTime:
            event.actionTarget, // Map actionTarget to estimatedTime for now
        cost: event.buttonStyle, // Map buttonStyle to cost for now
        valuePromise:
            event.actionType, // Map actionType to valuePromise for now
      );

      emit(state.copyWith(
        status: CTAStatus.success,
        callToAction: updatedCallToAction,
        message: 'CTA updated successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: CTAStatus.failure,
        message: 'Failed to update CTA: ${error.toString()}',
      ));
    }
  }

  Future<void> _onDelete(
    CTADelete event,
    Emitter<CTAState> emit,
  ) async {
    // Note: No DELETE endpoint available for CTA in the current backend configuration
    emit(state.copyWith(
      status: CTAStatus.failure,
      message: 'CTA deletion not supported by backend',
    ));
  }
}
