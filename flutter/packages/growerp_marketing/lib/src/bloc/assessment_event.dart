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
