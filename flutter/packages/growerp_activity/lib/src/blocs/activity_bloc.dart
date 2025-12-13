/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

part 'activity_event.dart';
part 'activity_state.dart';

const _activityLimit = 20;

EventTransformer<E> activityDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc(this.restClient) : super(const ActivityState()) {
    on<ActivityFetch>(_onActivityFetch,
        transformer: activityDroppable(const Duration(milliseconds: 100)));
    on<ActivityUpdate>(_onActivityUpdate);
    on<ActivityTimeEntryUpdate>(_onTimeEntryUpdate); //add,delete
    on<ActivityTimeEntryDelete>(_onTimeEntryDelete);
  }

  final RestClient restClient;
  int start = 0;

  /// general fetch of activity type entities
  Future<void> _onActivityFetch(
    ActivityFetch event,
    Emitter<ActivityState> emit,
  ) async {
    if (state.status == ActivityBlocStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.activities.length;
    }
    try {
      emit(state.copyWith(status: ActivityBlocStatus.loading));
      Activities compResult = await restClient.getActivity(
          activityType: event.activityType,
          my: event.my,
          start: start,
          searchString: event.searchString,
          limit: event.limit,
          activityId: event.activityId,
          isForDropDown: event.isForDropDown,
          companyPseudoId: event.companyUser?.getCompany()?.pseudoId,
          userPseudoId: event.companyUser?.getUser()?.pseudoId);
      return emit(state.copyWith(
        status: ActivityBlocStatus.success,
        activities: start == 0
            ? compResult.activities
            : (List.of(state.activities)..addAll(compResult.activities)),
        hasReachedMax:
            compResult.activities.length < _activityLimit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ActivityBlocStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onActivityUpdate(
    ActivityUpdate event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      List<Activity> activities = List.from(state.activities);
      emit(state.copyWith(status: ActivityBlocStatus.loading));
      if (event.activity.activityId.isNotEmpty) {
        // update existing activity
        Activity compResult =
            await restClient.updateActivity(activity: event.activity);
        int index = activities.indexWhere(
            (element) => element.activityId == event.activity.activityId);
        if (index != -1) activities.removeAt(index);
        if (compResult.statusId != ActivityStatus.closed) {
          activities.insert(0, compResult);
        }
        return emit(state.copyWith(
            status: ActivityBlocStatus.success,
            activities: activities,
            message:
                "${event.activity.activityType} ${event.activity.activityName} updated"));
      } else {
        // add new activity
        Activity compResult =
            await restClient.createActivity(activity: event.activity);
        // add activity to list
        activities.insert(0, compResult);
        return emit(state.copyWith(
            status: ActivityBlocStatus.success,
            activities: activities,
            message:
                "${event.activity.activityType} ${event.activity.activityName} added"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ActivityBlocStatus.failure,
          activities: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onTimeEntryUpdate(
    ActivityTimeEntryUpdate event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      TimeEntry compResult;
      if (event.timeEntry.timeEntryId != null) {
        compResult =
            await restClient.updateTimeEntry(timeEntry: event.timeEntry);
      } else {
        compResult =
            await restClient.createTimeEntry(timeEntry: event.timeEntry);
      }
      List<Activity> activities = List.from(state.activities);
      int index = activities
          .indexWhere((element) => element.activityId == compResult.activityId);
      if (event.timeEntry.timeEntryId == null) {
        activities[index].timeEntries.add(compResult);
      } else {
        int indexTe = activities[index].timeEntries.indexWhere(
            (element) => element.timeEntryId == compResult.timeEntryId);
        activities[index].timeEntries[indexTe] = compResult;
      }

      emit(state.copyWith(activities: activities));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ActivityBlocStatus.failure,
          activities: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onTimeEntryDelete(
    ActivityTimeEntryDelete event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      TimeEntry teApiResult =
          await restClient.deleteTimeEntry(timeEntry: event.timeEntry);
      List<Activity> activities = List.from(state.activities);
      int index = activities.indexWhere(
          (element) => element.activityId == teApiResult.activityId);
      activities[index].timeEntries.removeWhere(
          (element) => element.timeEntryId == teApiResult.timeEntryId);

      emit(state.copyWith(
        status: ActivityBlocStatus.success,
        activities: activities,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ActivityBlocStatus.failure,
          activities: [],
          message: await getDioError(e)));
    }
  }
}
