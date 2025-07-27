import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc(this.restClient) : super(const SubscriptionState()) {
    on<SubscriptionFetch>(_onSubscriptionFetch);
    on<SubscriptionUpdate>(_onSubscriptionUpdate);
    on<SubscriptionDelete>(_onSubscriptionDelete);
  }

  final RestClient restClient;
  int start = 0;
  Future<void> _onSubscriptionFetch(
    SubscriptionFetch event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      if (state.status == SubscriptionStatus.initial ||
          event.refresh ||
          event.searchString != '') {
        start = 0;
      } else {
        start = state.subscriptions.length;
      }
      emit(state.copyWith(status: SubscriptionStatus.loading));

      final subscriptions = await restClient.getSubscription(
        searchString: event.searchString,
        growerp: event.growerp,
        limit: event.limit ?? 20,
        start: start,
      );

      if (event.searchString.isEmpty) {
        return emit(state.copyWith(
          status: SubscriptionStatus.success,
          subscriptions: start == 0
              ? subscriptions.subscriptions
              : (List.of(state.subscriptions)
                ..addAll(subscriptions.subscriptions)),
          hasReachedMax: subscriptions.subscriptions.length < 20 ? true : false,
          searchString: '',
        ));
      } else {
        return emit(state.copyWith(
          status: SubscriptionStatus.success,
          subscriptions: subscriptions.subscriptions,
          hasReachedMax: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
          status: SubscriptionStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onSubscriptionUpdate(
    SubscriptionUpdate event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SubscriptionStatus.loading));
      List<Subscription> subscriptions = List.from(state.subscriptions);
      if (event.subscription.subscriptionId != null &&
          event.subscription.subscriptionId!.isNotEmpty) {
        Subscription updated = await restClient.updateSubscription(
            subscription: event.subscription);
        int index = subscriptions.indexWhere(
            (s) => s.subscriptionId == event.subscription.subscriptionId);
        if (index != -1) subscriptions[index] = updated;
        emit(state.copyWith(
          status: SubscriptionStatus.success,
          subscriptions: subscriptions,
          message: "Subscription updated",
        ));
      } else {
        Subscription created = await restClient.createSubscription(
            subscription: event.subscription);
        subscriptions.insert(0, created);
        emit(state.copyWith(
          status: SubscriptionStatus.success,
          subscriptions: subscriptions,
          message: "Subscription added",
        ));
      }
    } catch (e) {
      emit(state.copyWith(
          status: SubscriptionStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onSubscriptionDelete(
    SubscriptionDelete event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SubscriptionStatus.loading));
      List<Subscription> subscriptions = List.from(state.subscriptions);
      await restClient.deleteSubscription(subscription: event.subscription);
      subscriptions.removeWhere(
          (s) => s.subscriptionId == event.subscription.subscriptionId);
      emit(state.copyWith(
        status: SubscriptionStatus.success,
        subscriptions: subscriptions,
        message: "Subscription deleted",
      ));
    } catch (e) {
      emit(state.copyWith(
          status: SubscriptionStatus.failure, message: await getDioError(e)));
    }
  }
}
