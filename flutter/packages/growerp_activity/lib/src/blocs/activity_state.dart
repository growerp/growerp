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

part of 'activity_bloc.dart';

enum ActivityBlocStatus { initial, loading, success, failure }

class ActivityState extends Equatable {
  const ActivityState({
    this.status = ActivityBlocStatus.initial,
    this.message,
    this.activities = const <Activity>[],
    this.myactivities = const <Activity>[],
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final ActivityBlocStatus status;
  final String? message;
  final List<Activity> activities;
  final List<Activity> myactivities;
  final bool hasReachedMax; // all records retrieved
  final String searchString;

  ActivityState copyWith({
    ActivityBlocStatus? status,
    String? message,
    List<Activity>? activities,
    List<Activity>? myactivities,
    bool? hasReachedMax,
    String? searchString,
    bool? search,
  }) {
    return ActivityState(
      status: status ?? this.status,
      message: message,
      activities: activities ?? this.activities,
      myactivities: myactivities ?? this.myactivities,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  String toString() {
    return "$status { hasReachedMax: $hasReachedMax, "
        "activities: ${activities.length} message: $message}";
  }

  @override
  List<Object> get props => [
    status,
    activities,
    myactivities,
    hasReachedMax,
    searchString,
  ];
}
