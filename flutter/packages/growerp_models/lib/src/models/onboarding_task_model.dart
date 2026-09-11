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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_task_model.freezed.dart';
part 'onboarding_task_model.g.dart';

/// An item of the company onboarding checklist; [completed] is only filled in
/// when the task is part of an employee record.
@freezed
abstract class OnboardingTask with _$OnboardingTask {
  factory OnboardingTask({
    @Default("") String onboardingTaskId,
    @Default("") String description,
    @Default(0) int sequenceNum,
    @Default(false) bool completed,
  }) = _OnboardingTask;
  OnboardingTask._();

  factory OnboardingTask.fromJson(Map<String, dynamic> json) =>
      _$OnboardingTaskFromJson(json['onboardingTask'] ?? json);

  @override
  String toString() => 'OnboardingTask: $onboardingTaskId $description';
}
