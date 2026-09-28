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

part of 'course_learner_bloc.dart';

enum CourseLearnerStatus { initial, loading, success, failure }

class CourseLearnerState extends Equatable {
  final CourseLearnerStatus status;
  final List<CourseLearner> learners;

  /// the courses of the company, to assign from
  final List<Course> courses;

  /// the learner last created or changed, shown in the open dialog
  final CourseLearner? selected;
  final String? message;
  final bool hasReachedMax;
  final String searchString;

  const CourseLearnerState({
    this.status = CourseLearnerStatus.initial,
    this.learners = const [],
    this.courses = const [],
    this.selected,
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  CourseLearnerState copyWith({
    CourseLearnerStatus? status,
    List<CourseLearner>? learners,
    List<Course>? courses,
    CourseLearner? selected,
    String? message,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return CourseLearnerState(
      status: status ?? this.status,
      learners: learners ?? this.learners,
      courses: courses ?? this.courses,
      selected: selected ?? this.selected,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [
    status,
    learners,
    courses,
    selected,
    message,
    hasReachedMax,
    searchString,
  ];

  @override
  String toString() =>
      'CourseLearnerState(status: $status, learners: ${learners.length})';
}
