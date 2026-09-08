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

part of 'assessment_bloc.dart';

abstract class AssessmentEvent extends Equatable {
  const AssessmentEvent();

  @override
  List<Object?> get props => [];
}

class AssessmentFetch extends AssessmentEvent {
  const AssessmentFetch({
    this.statusId,
    this.refresh = false,
    this.limit = 20,
    this.searchString = '',
  });

  final String? statusId;
  final bool refresh;
  final int limit;
  final String searchString;

  @override
  List<Object?> get props => [statusId, refresh, limit, searchString];
}

class AssessmentFetchAll extends AssessmentEvent {
  const AssessmentFetchAll({
    this.assessmentId,
    this.pseudoId,
    this.ownerPartyId,
  });

  final String? assessmentId;
  final String? pseudoId;
  final String? ownerPartyId;

  @override
  List<Object?> get props => [assessmentId, pseudoId, ownerPartyId];
}

class AssessmentCreate extends AssessmentEvent {
  const AssessmentCreate(this.assessment);

  final Assessment assessment;

  @override
  List<Object?> get props => [assessment];
}

class AssessmentUpdate extends AssessmentEvent {
  const AssessmentUpdate(this.assessment);

  final Assessment assessment;

  @override
  List<Object?> get props => [assessment];
}

class AssessmentDelete extends AssessmentEvent {
  const AssessmentDelete(this.assessment);

  final Assessment assessment;

  @override
  List<Object?> get props => [assessment];
}

class AssessmentSubmit extends AssessmentEvent {
  const AssessmentSubmit({
    required this.assessmentId,
    required this.answers,
    required this.respondentName,
    required this.respondentEmail,
    this.respondentPhone,
    this.respondentCompany,
    this.ownerPartyId,
    this.campaignId,
  });

  final String assessmentId;
  final Map<String, dynamic> answers;
  final String respondentName;
  final String respondentEmail;
  final String? respondentPhone;
  final String? respondentCompany;
  final String? ownerPartyId;
  final String? campaignId;

  @override
  List<Object?> get props => [
    assessmentId,
    answers,
    respondentName,
    respondentEmail,
    respondentPhone,
    respondentCompany,
    ownerPartyId,
    campaignId,
  ];
}

final class AssessmentFetchResults extends AssessmentEvent {
  const AssessmentFetchResults({
    required this.assessmentId,
    this.start = 0,
    this.limit = 10,
    this.refresh = false,
  });

  final String assessmentId;
  final int start;
  final int limit;
  final bool refresh;

  @override
  List<Object> get props => [assessmentId, start, limit, refresh];
}

final class AssessmentFetchQuestions extends AssessmentEvent {
  const AssessmentFetchQuestions({required this.assessmentId});

  final String assessmentId;

  @override
  List<Object> get props => [assessmentId];
}

final class AssessmentFetchQuestionOptions extends AssessmentEvent {
  const AssessmentFetchQuestionOptions({
    required this.assessmentId,
    required this.assessmentQuestionId,
  });

  final String assessmentId;
  final String assessmentQuestionId;

  @override
  List<Object> get props => [assessmentId, assessmentQuestionId];
}

final class AssessmentFetchThresholds extends AssessmentEvent {
  const AssessmentFetchThresholds({required this.assessmentId});

  final String assessmentId;

  @override
  List<Object> get props => [assessmentId];
}

final class AssessmentFetchLeads extends AssessmentEvent {
  const AssessmentFetchLeads({
    required this.assessmentId,
    this.start = 0,
    this.limit = 50,
    this.refresh = false,
  });

  final String assessmentId;
  final int start;
  final int limit;
  final bool refresh;

  @override
  List<Object> get props => [assessmentId, start, limit, refresh];
}

final class AssessmentSearchRequested extends AssessmentEvent {
  const AssessmentSearchRequested({required this.query, this.limit = 20});

  final String query;
  final int limit;

  @override
  List<Object> get props => [query, limit];
}
