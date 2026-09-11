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

part of 'onboarding_task_bloc.dart';

enum OnboardingTaskStatus { initial, loading, success, failure }

class OnboardingTaskState extends Equatable {
  const OnboardingTaskState({
    this.status = OnboardingTaskStatus.initial,
    this.onboardingTasks = const <OnboardingTask>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final OnboardingTaskStatus status;
  final String? message;
  final List<OnboardingTask> onboardingTasks;
  final bool hasReachedMax;
  final String searchString;

  OnboardingTaskState copyWith({
    OnboardingTaskStatus? status,
    String? message,
    List<OnboardingTask>? onboardingTasks,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return OnboardingTaskState(
      status: status ?? this.status,
      onboardingTasks: onboardingTasks ?? this.onboardingTasks,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [onboardingTasks, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #onboardingTasks: ${onboardingTasks.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
