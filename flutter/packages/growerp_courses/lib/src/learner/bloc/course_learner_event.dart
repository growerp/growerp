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

abstract class CourseLearnerEvent extends Equatable {
  const CourseLearnerEvent();

  @override
  List<Object?> get props => [];
}

class CourseLearnerFetch extends CourseLearnerEvent {
  final String? searchString;
  final bool refresh;

  const CourseLearnerFetch({this.searchString, this.refresh = false});

  @override
  List<Object?> get props => [searchString, refresh];
}

/// Create (no partyId) or update the person
class CourseLearnerUpdate extends CourseLearnerEvent {
  final CourseLearner learner;

  const CourseLearnerUpdate(this.learner);

  @override
  List<Object?> get props => [learner];
}

class CourseLearnerAssign extends CourseLearnerEvent {
  final CourseLearner learner;
  final String courseId;

  const CourseLearnerAssign(this.learner, this.courseId);

  @override
  List<Object?> get props => [learner, courseId];
}

class CourseLearnerUnassign extends CourseLearnerEvent {
  final CourseLearner learner;
  final String courseId;

  const CourseLearnerUnassign(this.learner, this.courseId);

  @override
  List<Object?> get props => [learner, courseId];
}
