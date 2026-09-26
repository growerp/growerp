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

/// The quiz of one module as its own page. Pops with the score percent of the
/// last submitted attempt, or null when nothing was submitted.
class CourseQuizScreen extends StatelessWidget {
  final String courseId;
  final CourseModule module;

  const CourseQuizScreen({
    super.key,
    required this.courseId,
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseQuizBloc(
        restClient: context.read<RestClient>(),
        courseId: courseId,
        moduleId: module.moduleId!,
      )..add(const CourseQuizLoad()),
      child: _CourseQuizView(module: module),
    );
  }
}

class _CourseQuizView extends StatelessWidget {
  final CourseModule module;
  const _CourseQuizView({required this.module});

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
        if (result != null) _scoreCard(context, result),
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
