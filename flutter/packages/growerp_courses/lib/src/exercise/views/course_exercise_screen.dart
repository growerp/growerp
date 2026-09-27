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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../tutor/course_tutor_panel.dart';

/// A learner doing an exercise: the task, an answer, the AI (and instructor)
/// feedback on it. Pops with the latest submission when one was handed in.
class CourseExerciseScreen extends StatefulWidget {
  final String courseId;
  final String exerciseId;

  const CourseExerciseScreen({
    super.key,
    required this.courseId,
    required this.exerciseId,
  });

  @override
  State<CourseExerciseScreen> createState() => _CourseExerciseScreenState();
}

class _CourseExerciseScreenState extends State<CourseExerciseScreen> {
  final _answer = TextEditingController();
  CourseExercise? _exercise;
  List<CourseSubmission> _submissions = [];
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final detail = await context.read<RestClient>().getCourseExercise(
        courseId: widget.courseId,
        exerciseId: widget.exerciseId,
      );
      if (!mounted) return;
      setState(() {
        _exercise = detail.exercise;
        _submissions = detail.submissions;
        // continue from the last answer
        if (_submissions.isNotEmpty) _answer.text = _submissions.first.answer ?? '';
        _loading = false;
      });
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) {
        setState(() {
          _error = message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_answer.text.trim().isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await context.read<RestClient>().submitCourseExercise(
        courseId: widget.courseId,
        exerciseId: widget.exerciseId,
        answer: _answer.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submissions = [result.submission, ..._submissions];
        _submitting = false;
        _submitted = true;
      });
      if (result.aiError != null) {
        HelperFunctions.showMessage(
          context,
          CoursesLocalizations.of(context)!.courses_exerciseNotGraded,
          Colors.orange,
        );
      }
    } catch (e) {
      final message = await getDioError(e);
      if (!mounted) return;
      setState(() => _submitting = false);
      HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(
            context,
          ).pop(_submitted && _submissions.isNotEmpty ? _submissions.first : null);
        }
      },
      child: Scaffold(
        key: const Key('CourseExerciseScreen'),
        appBar: AppBar(
          title: Text(
            _exercise?.isProject ?? false
                ? l10n.courses_capstoneProject
                : l10n.courses_exercise,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final exercise = _exercise!;
    final isCode = exercise.exerciseType == CourseExerciseType.code;
    final latest = _submissions.firstOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              MarkdownBody(data: exercise.prompt ?? '', selectable: true),
              const SizedBox(height: 24),
              TextField(
                key: const Key('exerciseAnswer'),
                controller: _answer,
                minLines: 6,
                maxLines: 20,
                style: isCode ? const TextStyle(fontFamily: 'monospace') : null,
                decoration: InputDecoration(
                  labelText: l10n.courses_yourAnswer,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('exerciseHint'),
                    icon: const Icon(Icons.lightbulb_outline),
                    label: Text(l10n.courses_getAHint),
                    onPressed: () => showCourseTutor(
                      context,
                      courseId: widget.courseId,
                      lessonId: exercise.lessonId,
                      title: exercise.title,
                      hints: true,
                      extraContext:
                          'EXERCISE: ${exercise.title}\n${exercise.prompt ?? ''}'
                          '${_answer.text.trim().isEmpty ? '' : '\n\nTHE LEARNER ANSWER SO FAR:\n${_answer.text.trim()}'}',
                    ),
                  ),
                  ElevatedButton.icon(
                    key: const Key('exerciseSubmit'),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(l10n.courses_submitForFeedback),
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
              if (latest != null) ...[
                const SizedBox(height: 24),
                _FeedbackCard(submission: latest),
              ],
              if (_submissions.length > 1)
                ExpansionTile(
                  key: const Key('exerciseAttempts'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    l10n.courses_earlierAttempts(
                      (_submissions.length - 1).toString(),
                    ),
                  ),
                  children: _submissions
                      .skip(1)
                      .map(
                        (s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            s.answer ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(s.score == null ? '-' : '${s.score}%'),
                          onTap: () => setState(
                            () => _answer.text = s.answer ?? '',
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final CourseSubmission submission;

  const _FeedbackCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final score = submission.score;
    final color = score == null
        ? Colors.grey
        : submission.passed
        ? Colors.green
        : Colors.orange;
    return Card(
      key: const Key('exerciseFeedback'),
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  submission.passed ? Icons.emoji_events : Icons.rate_review,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    score == null
                        ? l10n.courses_waitingForReview
                        : submission.passed
                        ? l10n.courses_exercisePassed(score.toString())
                        : l10n.courses_exerciseScore(score.toString()),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (submission.instructorFeedback?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                l10n.courses_instructorFeedback,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                submission.instructorFeedback!,
                key: const Key('instructorFeedback'),
              ),
            ],
            if (submission.aiFeedback?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                l10n.courses_aiFeedback,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(submission.aiFeedback!),
            ],
            if (submission.strengths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.courses_strengths,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ...submission.strengths.map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check, color: Colors.green),
                  title: Text(s),
                ),
              ),
            ],
            if (submission.improvements.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.courses_toImprove,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ...submission.improvements.map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.trending_up, color: Colors.orange),
                  title: Text(s),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
