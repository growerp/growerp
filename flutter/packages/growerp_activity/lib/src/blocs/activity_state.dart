/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
