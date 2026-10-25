import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// AssessmentFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<AssessmentState> assessmentState(
  AssessmentStatus status, {
  List<Assessment>? assessments,
  String? message,
}) {
  var m = isA<AssessmentState>().having((s) => s.status, 'status', status);
  if (assessments != null) {
    m = m.having((s) => s.assessments, 'assessments', assessments);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  const scorecard = Assessment(
    assessmentId: 'A1',
    pseudoId: 'a1',
    assessmentName: 'Scorecard',
    status: 'ACTIVE',
  );
  const quiz = Assessment(
    assessmentId: 'A2',
    pseudoId: 'a2',
    assessmentName: 'Quiz',
    status: 'ACTIVE',
  );
  const result1 = AssessmentResult(
    assessmentResultId: 'R1',
    score: 80,
    leadStatus: 'HOT',
    respondentName: 'Jane',
  );
  const result2 = AssessmentResult(assessmentResultId: 'R2', score: 20);
  const q1 = AssessmentQuestion(
    assessmentQuestionId: 'Q1',
    questionText: 'Size?',
    options: [AssessmentQuestionOption(optionText: 'Small', optionScore: 1)],
  );
  const q2 = AssessmentQuestion(
    assessmentQuestionId: 'Q2',
    questionText: 'Budget?',
  );

  setUp(() => restClient = MockRestClient());

  AssessmentBloc build() => AssessmentBloc(restClient);

  group('AssessmentFetch', () {
    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetch_initial_emitsFirstPage',
      setUp: () =>
          when(() => restClient.getAssessment(start: 0, limit: 20)).thenAnswer(
            (_) async => const Assessments(assessments: [scorecard, quiz]),
          ),
      build: build,
      act: (bloc) => bloc.add(const AssessmentFetch()),
      wait: fetchWait,
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
          assessments: [scorecard, quiz],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.getAssessment(start: 1, limit: 20),
      ).thenAnswer((_) async => const Assessments(assessments: [quiz])),
      build: build,
      seed: () => const AssessmentState(
        status: AssessmentStatus.success,
        assessments: [scorecard],
      ),
      act: (bloc) => bloc.add(const AssessmentFetch()),
      wait: fetchWait,
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
          assessments: [scorecard, quiz],
        ),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getAssessment(start: 0, limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const AssessmentFetch()),
      wait: fetchWait,
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.failure, message: 'No access'),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentSearchRequested_threeChars_refetchesWithSearch',
      setUp: () => when(
        () =>
            restClient.getAssessment(start: 0, limit: 20, searchString: 'Sco'),
      ).thenAnswer((_) async => const Assessments(assessments: [scorecard])),
      build: build,
      seed: () => const AssessmentState(
        status: AssessmentStatus.success,
        assessments: [scorecard, quiz],
      ),
      act: (bloc) => bloc.add(const AssessmentSearchRequested(query: 'Sco')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.success, assessments: [scorecard]),
      ],
    );
  });

  group('AssessmentFetchAll', () {
    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchAll_publicPseudoId_setsSelectedAssessment',
      setUp: () => when(
        () => restClient.getAssessmentComplete(
          pseudoId: 'a1',
          ownerPartyId: 'O1',
        ),
      ).thenAnswer((_) async => scorecard),
      build: build,
      act: (bloc) => bloc.add(
        const AssessmentFetchAll(pseudoId: 'a1', ownerPartyId: 'O1'),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
        ).having((s) => s.selectedAssessment, 'selected', scorecard),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchAll_parseError_emitsFailure',
      setUp: () => when(
        () => restClient.getAssessmentComplete(assessmentId: 'A1'),
      ).thenThrow(const FormatException('bad json')),
      build: build,
      act: (bloc) => bloc.add(const AssessmentFetchAll(assessmentId: 'A1')),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.failure),
      ],
    );
  });

  group('AssessmentCreate / Update / Delete', () {
    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentCreate_emptyPseudoId_sendsNullAndInsertsFirst',
      setUp: () => when(
        () => restClient.createAssessment(
          assessmentName: 'Quiz',
          status: 'ACTIVE',
        ),
      ).thenAnswer((_) async => quiz),
      build: build,
      seed: () => const AssessmentState(assessments: [scorecard]),
      act: (bloc) => bloc.add(
        const AssessmentCreate(
          Assessment(pseudoId: '', assessmentName: 'Quiz', status: 'ACTIVE'),
        ),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
          assessments: [quiz, scorecard],
        ),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentUpdate_backendDropsName_keepsEnteredName',
      setUp: () =>
          when(
            () => restClient.updateAssessment(
              assessmentId: 'A2',
              pseudoId: 'a2',
              assessmentName: 'Quiz 2',
              status: 'ACTIVE',
            ),
          ).thenAnswer(
            (_) async => const Assessment(
              assessmentId: 'A2',
              assessmentName: 'Unnamed Assessment',
              status: 'ACTIVE',
            ),
          ),
      build: build,
      seed: () => const AssessmentState(assessments: [scorecard, quiz]),
      act: (bloc) =>
          bloc.add(AssessmentUpdate(quiz.copyWith(assessmentName: 'Quiz 2'))),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.success).having(
          (s) => s.assessments.map((a) => a.assessmentName),
          'names',
          ['Scorecard', 'Quiz 2'],
        ),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteAssessment(assessmentId: 'A1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => const AssessmentState(assessments: [scorecard, quiz]),
      act: (bloc) => bloc.add(const AssessmentDelete(scorecard)),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.success, assessments: [quiz]),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteAssessment(assessmentId: 'A1'),
      ).thenThrow(dioError('Has results')),
      build: build,
      act: (bloc) => bloc.add(const AssessmentDelete(scorecard)),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.failure, message: 'Has results'),
      ],
    );
  });

  group('AssessmentSubmit', () {
    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentSubmit_answers_sendsJsonAndSetsScoreResult',
      setUp: () => when(
        () => restClient.submitAssessment(
          assessmentId: 'A1',
          answers: jsonEncode({'Q1': 'Small'}),
          respondentName: 'Jane',
          respondentEmail: 'jane@x.com',
          campaignId: 'C1',
        ),
      ).thenAnswer((_) async => result1),
      build: build,
      act: (bloc) => bloc.add(
        const AssessmentSubmit(
          assessmentId: 'A1',
          answers: {'Q1': 'Small'},
          respondentName: 'Jane',
          respondentEmail: 'jane@x.com',
          campaignId: 'C1',
        ),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.success)
            .having((s) => s.results, 'results', [result1])
            .having((s) => s.scoreResult?.score, 'score', 80)
            .having((s) => s.scoreResult?.leadStatus, 'leadStatus', 'HOT'),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentSubmit_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.submitAssessment(
          assessmentId: 'A1',
          answers: '{}',
          respondentName: 'Jane',
          respondentEmail: 'jane@x.com',
        ),
      ).thenThrow(dioError('Email invalid')),
      build: build,
      act: (bloc) => bloc.add(
        const AssessmentSubmit(
          assessmentId: 'A1',
          answers: {},
          respondentName: 'Jane',
          respondentEmail: 'jane@x.com',
        ),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.failure, message: 'Email invalid'),
      ],
    );
  });

  group('AssessmentFetchResults / Leads', () {
    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchResults_noAssessment_loadsAllResults',
      setUp: () =>
          when(
            () => restClient.getAllAssessmentResults(start: 0, limit: 10),
          ).thenAnswer(
            (_) async => const AssessmentResults(results: [result1, result2]),
          ),
      build: build,
      act: (bloc) => bloc.add(
        const AssessmentFetchResults(assessmentId: '', refresh: true),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
        ).having((s) => s.results, 'results', [result1, result2]),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchResults_moreForAssessment_appends',
      setUp: () => when(
        () => restClient.getAssessmentResults(
          assessmentId: 'A1',
          start: 1,
          limit: 10,
        ),
      ).thenAnswer((_) async => const AssessmentResults(results: [result2])),
      build: build,
      seed: () => const AssessmentState(results: [result1]),
      act: (bloc) =>
          bloc.add(const AssessmentFetchResults(assessmentId: 'A1', start: 1)),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
        ).having((s) => s.results, 'results', [result1, result2]),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchLeads_refresh_replacesResults',
      setUp: () => when(
        () => restClient.getAssessmentResults(
          assessmentId: 'A1',
          start: 0,
          limit: 50,
        ),
      ).thenAnswer((_) async => const AssessmentResults(results: [result2])),
      build: build,
      seed: () => const AssessmentState(results: [result1]),
      act: (bloc) => bloc.add(
        const AssessmentFetchLeads(assessmentId: 'A1', refresh: true),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
        ).having((s) => s.results, 'results', [result2]),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchResults_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getAllAssessmentResults(start: 0, limit: 10),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const AssessmentFetchResults(assessmentId: '')),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.failure, message: 'No access'),
      ],
    );
  });

  group('AssessmentFetchQuestions / Options / Thresholds', () {
    void stubQuestions() => when(
      () => restClient.getAssessmentQuestions(assessmentId: 'A1'),
    ).thenAnswer((_) async => const AssessmentQuestions(questions: [q1, q2]));

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchQuestions_assessment_setsQuestions',
      setUp: stubQuestions,
      build: build,
      act: (bloc) =>
          bloc.add(const AssessmentFetchQuestions(assessmentId: 'A1')),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
        ).having((s) => s.questions, 'questions', [q1, q2]),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchQuestionOptions_question_storesItsOptionsByQuestionId',
      setUp: stubQuestions,
      build: build,
      act: (bloc) => bloc.add(
        const AssessmentFetchQuestionOptions(
          assessmentId: 'A1',
          assessmentQuestionId: 'Q1',
        ),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.success).having(
          (s) => s.options['Q1']?.map((o) => o.optionText),
          'Q1 options',
          ['Small'],
        ),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchQuestionOptions_unknownQuestion_storesEmptyList',
      setUp: stubQuestions,
      build: build,
      act: (bloc) => bloc.add(
        const AssessmentFetchQuestionOptions(
          assessmentId: 'A1',
          assessmentQuestionId: 'Q9',
        ),
      ),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
        ).having((s) => s.options['Q9'], 'Q9 options', isEmpty),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchThresholds_assessment_setsThresholds',
      setUp: () =>
          when(
            () => restClient.getAssessmentThresholds(assessmentId: 'A1'),
          ).thenAnswer(
            (_) async => const ScoringThresholds(
              thresholds: [ScoringThreshold(minScore: 70, leadStatus: 'HOT')],
            ),
          ),
      build: build,
      act: (bloc) =>
          bloc.add(const AssessmentFetchThresholds(assessmentId: 'A1')),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(
          AssessmentStatus.success,
        ).having((s) => s.thresholds.single.leadStatus, 'leadStatus', 'HOT'),
      ],
    );

    blocTest<AssessmentBloc, AssessmentState>(
      'AssessmentFetchQuestions_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getAssessmentQuestions(assessmentId: 'A1'),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) =>
          bloc.add(const AssessmentFetchQuestions(assessmentId: 'A1')),
      expect: () => [
        assessmentState(AssessmentStatus.loading),
        assessmentState(AssessmentStatus.failure, message: 'No access'),
      ],
    );
  });

  group('QuestionBloc', () {
    QuestionBloc build() => QuestionBloc(restClient: restClient);

    TypeMatcher<QuestionState> questionState(
      QuestionStatus status, {
      List<AssessmentQuestion>? questions,
      String? message,
    }) {
      var m = isA<QuestionState>().having((s) => s.status, 'status', status);
      if (questions != null) {
        m = m.having((s) => s.questions, 'questions', questions);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    blocTest<QuestionBloc, QuestionState>(
      'QuestionLoad_assessment_setsQuestionsAndAssessmentId',
      setUp: () => when(
        () => restClient.getAssessmentQuestions(assessmentId: 'A1'),
      ).thenAnswer((_) async => const AssessmentQuestions(questions: [q1])),
      build: build,
      act: (bloc) => bloc.add(const QuestionLoad('A1')),
      expect: () => [
        questionState(QuestionStatus.loading),
        questionState(
          QuestionStatus.success,
          questions: [q1],
        ).having((s) => s.assessmentId, 'assessmentId', 'A1'),
      ],
    );

    blocTest<QuestionBloc, QuestionState>(
      'QuestionCreate_defaults_sendsMultipleChoiceOptionMapsAndAppends',
      setUp: () => when(
        () => restClient.createAssessmentQuestion(
          assessmentId: 'A1',
          questionText: 'Budget?',
          questionType: 'MULTIPLE_CHOICE',
          isRequired: 'N',
          options: [
            {'optionText': 'Low', 'optionScore': 1, 'optionSequence': 1},
          ],
        ),
      ).thenAnswer((_) async => q2),
      build: build,
      seed: () => const QuestionState(assessmentId: 'A1', questions: [q1]),
      act: (bloc) => bloc.add(
        const QuestionCreate(
          assessmentId: 'A1',
          questionText: 'Budget?',
          options: [
            AssessmentQuestionOption(
              optionText: 'Low',
              optionScore: 1,
              optionSequence: 1,
            ),
          ],
        ),
      ),
      expect: () => [
        questionState(QuestionStatus.loading),
        questionState(
          QuestionStatus.success,
          questions: [q1, q2],
          message: 'Question created successfully',
        ),
      ],
    );

    blocTest<QuestionBloc, QuestionState>(
      'QuestionUpdate_required_sendsYAndReplaces',
      setUp: () =>
          when(
            () => restClient.updateAssessmentQuestion(
              assessmentId: 'A1',
              questionId: 'Q2',
              questionText: 'Budget per year?',
              isRequired: 'Y',
            ),
          ).thenAnswer(
            (_) async => const AssessmentQuestion(
              assessmentQuestionId: 'Q2',
              questionText: 'Budget per year?',
            ),
          ),
      build: build,
      seed: () => const QuestionState(assessmentId: 'A1', questions: [q1, q2]),
      act: (bloc) => bloc.add(
        const QuestionUpdate(
          assessmentId: 'A1',
          questionId: 'Q2',
          questionText: 'Budget per year?',
          isRequired: true,
        ),
      ),
      expect: () => [
        questionState(QuestionStatus.loading),
        questionState(QuestionStatus.success).having(
          (s) => s.questions.map((q) => q.questionText),
          'texts',
          ['Size?', 'Budget per year?'],
        ),
      ],
    );

    blocTest<QuestionBloc, QuestionState>(
      'QuestionDelete_question_removesIt',
      setUp: () => when(
        () => restClient.deleteAssessmentQuestion(
          assessmentId: 'A1',
          questionId: 'Q1',
        ),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => const QuestionState(assessmentId: 'A1', questions: [q1, q2]),
      act: (bloc) => bloc.add(const QuestionDelete('Q1')),
      expect: () => [
        questionState(QuestionStatus.loading),
        questionState(QuestionStatus.success, questions: [q2]),
      ],
    );

    blocTest<QuestionBloc, QuestionState>(
      'QuestionLoad_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getAssessmentQuestions(assessmentId: 'A1'),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const QuestionLoad('A1')),
      expect: () => [
        questionState(QuestionStatus.loading),
        questionState(QuestionStatus.failure, message: 'No access'),
      ],
    );
  });
}
