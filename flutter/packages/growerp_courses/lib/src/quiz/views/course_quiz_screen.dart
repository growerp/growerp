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

import 'package:growerp_courses/l10n/generated/courses_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/course_quiz_bloc.dart';
import '../../tutor/course_tutor_panel.dart';

/// The quiz of one module as its own page. Pops with the score percent of the
/// last submitted attempt, or null when nothing was submitted.
class CourseQuizScreen extends StatelessWidget {
  final String courseId;
  final CourseModule module;

  /// Testing out of the module before studying it
  final bool placement;

  /// Open a lesson to review, after the quiz is closed
  final void Function(CourseLesson lesson)? onReviewLesson;

  const CourseQuizScreen({
    super.key,
    required this.courseId,
    required this.module,
    this.placement = false,
    this.onReviewLesson,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseQuizBloc(
        restClient: context.read<RestClient>(),
        courseId: courseId,
        moduleId: module.moduleId!,
        placement: placement,
      )..add(const CourseQuizLoad()),
      child: _CourseQuizView(
        courseId: courseId,
        module: module,
        placement: placement,
        onReviewLesson: onReviewLesson,
      ),
    );
  }
}

class _CourseQuizView extends StatelessWidget {
  final String courseId;
  final CourseModule module;
  final bool placement;
  final void Function(CourseLesson lesson)? onReviewLesson;
  const _CourseQuizView({
    required this.courseId,
    required this.module,
    this.placement = false,
    this.onReviewLesson,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseQuizBloc, CourseQuizState>(
      listener: (context, state) {
        if (state.message != null) {
          HelperFunctions.showMessage(context, state.message!, Colors.red);
        }
      },
      builder: (context, state) {
        final score = state.result?.scorePercent;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop(score);
          },
          child: Scaffold(
            key: const Key('CourseQuizScreen'),
            appBar: AppBar(
              title: Text(
                CoursesLocalizations.of(
                  context,
                )!.courses_quizTitle(module.title),
              ),
            ),
            body: switch (state.status) {
              CourseQuizStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              CourseQuizStatus.failure => Center(
                child: Text(
                  state.message ??
                      CoursesLocalizations.of(
                        context,
                      )!.courses_couldNotLoadQuiz,
                ),
              ),
              _ => _questions(context, state),
            },
          ),
        );
      },
    );
  }

  Widget _questions(BuildContext context, CourseQuizState state) {
    final result = state.result;
    final submitted = state.status == CourseQuizStatus.submitted;
    return ListView(
      key: const Key('quizQuestions'),
      padding: const EdgeInsets.all(16),
      children: [
        if (placement && result == null)
          Card(
            key: const Key('placementInfo'),
            child: ListTile(
              leading: const Icon(Icons.fast_forward),
              title: Text(
                CoursesLocalizations.of(context)!.courses_testOutInfo,
              ),
            ),
          ),
        if (result != null) _scoreCard(context, result),
        if (result != null && !result.passed)
          _reviewCard(context, state, result),
        for (var i = 0; i < state.questions.length; i++)
          _question(context, state, i, submitted ? result!.results[i] : null),
        const SizedBox(height: 16),
        Center(
          child: submitted
              ? Wrap(
                  spacing: 16,
                  children: [
                    OutlinedButton(
                      key: const Key('quizRetry'),
                      onPressed: () => context.read<CourseQuizBloc>().add(
                        const CourseQuizRetry(),
                      ),
                      child: Text(
                        CoursesLocalizations.of(context)!.courses_tryAgain,
                      ),
                    ),
                    ElevatedButton(
                      key: const Key('quizClose'),
                      onPressed: () =>
                          Navigator.of(context).pop(result!.scorePercent),
                      child: Text(
                        CoursesLocalizations.of(context)!.courses_close,
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  key: const Key('quizSubmit'),
                  onPressed:
                      state.allAnswered &&
                          state.status == CourseQuizStatus.answering
                      ? () => context.read<CourseQuizBloc>().add(
                          const CourseQuizSubmit(),
                        )
                      : null,
                  child: Text(
                    CoursesLocalizations.of(context)!.courses_submitAnswers,
                  ),
                ),
        ),
      ],
    );
  }

  /// Answered wrong: the lessons to look at again, and the tutor explaining
  Widget _reviewCard(
    BuildContext context,
    CourseQuizState state,
    CourseQuizResult result,
  ) {
    final l10n = CoursesLocalizations.of(context)!;
    final lessons = (module.lessons ?? [])
        .where((l) => result.weakLessonIds.contains(l.lessonId))
        .toList();
    final missed = StringBuffer();
    for (var i = 0; i < state.questions.length && i < result.results.length; i++) {
      final outcome = result.results[i];
      if (outcome.correct) continue;
      final q = state.questions[i];
      final chosen = state.answers[i];
      missed.writeln('QUESTION: ${q.question}');
      if (chosen != null && chosen < q.options.length) {
        missed.writeln('LEARNER ANSWERED: ${q.options[chosen]}');
      }
      final correct = outcome.correctIndex;
      if (correct != null && correct < q.options.length) {
        missed.writeln('CORRECT ANSWER: ${q.options[correct]}');
      }
      missed.writeln();
    }
    return Card(
      key: const Key('quizReview'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lessons.isNotEmpty) ...[
              Text(
                l10n.courses_reviewTheseLessons,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final (i, lesson) in lessons.indexed)
                ListTile(
                  key: Key('reviewLesson$i'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(lesson.title),
                  onTap: onReviewLesson == null
                      ? null
                      : () {
                          Navigator.of(context).pop(result.scorePercent);
                          onReviewLesson!(lesson);
                        },
                ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('quizExplain'),
                icon: const Icon(Icons.psychology_outlined),
                label: Text(l10n.courses_explainMyMistakes),
                onPressed: () => showCourseTutor(
                  context,
                  courseId: courseId,
                  lessonId: lessons.firstOrNull?.lessonId,
                  title: l10n.courses_explainMyMistakes,
                  extraContext: 'QUIZ OF MODULE ${module.title}, ANSWERED WRONG:\n$missed',
                  firstMessage: l10n.courses_explainMyMistakesPrompt,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(BuildContext context, CourseQuizResult result) {
    final color = result.passed ? Colors.green : Colors.orange;
    return Card(
      key: const Key('quizScore'),
      color: color.withValues(alpha: 0.15),
      child: ListTile(
        leading: Icon(
          result.passed ? Icons.emoji_events : Icons.replay,
          color: color,
          size: 36,
        ),
        title: Text(
          '${result.scorePercent}%',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Text(
          result.passed
              ? CoursesLocalizations.of(context)!.courses_passed
              : CoursesLocalizations.of(context)!.courses_needToPass(
                  CourseProgress.quizPassPercent.toString(),
                ),
        ),
      ),
    );
  }

  Widget _question(
    BuildContext context,
    CourseQuizState state,
    int index,
    CourseQuizAnswerResult? outcome,
  ) {
    final question = state.questions[index];
    return Card(
      key: Key('quizQuestion$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${question.question}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RadioGroup<int>(
              groupValue: state.answers[index],
              onChanged: (value) {
                if (value != null && outcome == null) {
                  context.read<CourseQuizBloc>().add(
                    CourseQuizAnswer(index, value),
                  );
                }
              },
              child: Column(
                children: [
                  for (var o = 0; o < question.options.length; o++)
                    RadioListTile<int>(
                      key: Key('quizOption${index}_$o'),
                      value: o,
                      enabled: outcome == null,
                      title: Text(question.options[o]),
                      secondary: outcome == null
                          ? null
                          : o == outcome.correctIndex
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : o == state.answers[index]
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : null,
                    ),
                ],
              ),
            ),
            if (outcome?.explanation != null &&
                outcome!.explanation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Text(
                  outcome.explanation!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
