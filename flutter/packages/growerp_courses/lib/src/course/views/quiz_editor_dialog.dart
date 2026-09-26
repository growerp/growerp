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

import '../bloc/course_bloc.dart';

/// The quiz questions of one module: add, edit, delete. Shows the module as
/// reloaded by the [CourseBloc] after every change.
class QuizEditorDialog extends StatelessWidget {
  final String moduleId;

  const QuizEditorDialog({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final module = context.select<CourseBloc, CourseModule?>(
      (bloc) => bloc.state.selectedCourse?.modules
          ?.where((m) => m.moduleId == moduleId)
          .firstOrNull,
    );
    final questions = module?.quizQuestions ?? [];
    return Dialog(
      key: const Key('QuizEditorDialog'),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: CoursesLocalizations.of(
          context,
        )!.courses_quizTitle(module?.title ?? ''),
        width: 600,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: questions.isEmpty
                  ? Center(
                      child: Text(
                        CoursesLocalizations.of(
                          context,
                        )!.courses_noQuestionsYet,
                      ),
                    )
                  : ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        final correct =
                            q.correctIndex != null &&
                                q.correctIndex! < q.options.length
                            ? q.options[q.correctIndex!]
                            : '';
                        return ListTile(
                          key: Key('quizQuestion$index'),
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(q.question),
                          subtitle: Text(
                            CoursesLocalizations.of(
                              context,
                            )!.courses_answerIs(correct),
                          ),
                          onTap: () => _edit(context, q),
                          trailing: IconButton(
                            key: Key('deleteQuestion$index'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => context.read<CourseBloc>().add(
                              CourseQuizQuestionDelete(q.questionId!),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    key: const Key('addQuestion'),
                    icon: const Icon(Icons.add),
                    label: Text(
                      CoursesLocalizations.of(context)!.courses_addQuestion,
                    ),
                    onPressed: () => _edit(context, null),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const Key('closeQuiz'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      CoursesLocalizations.of(context)!.courses_close,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, CourseQuizQuestion? question) async {
    final saved = await showDialog<CourseQuizQuestion>(
      context: context,
      builder: (_) => _QuestionDialog(moduleId: moduleId, question: question),
    );
    if (saved != null && context.mounted) {
      context.read<CourseBloc>().add(CourseQuizQuestionSave(saved));
    }
  }
}

class _QuestionDialog extends StatefulWidget {
  final String moduleId;
  final CourseQuizQuestion? question;

  const _QuestionDialog({required this.moduleId, this.question});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  static const _optionCount = 4;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _question;
  late final TextEditingController _explanation;
  late final List<TextEditingController> _options;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _question = TextEditingController(text: q?.question ?? '');
    _explanation = TextEditingController(text: q?.explanation ?? '');
    _options = List.generate(
      _optionCount,
      (i) => TextEditingController(
        text: q != null && i < q.options.length ? q.options[i] : '',
      ),
    );
    _correct = q?.correctIndex ?? 0;
  }

  @override
  void dispose() {
    _question.dispose();
    _explanation.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.question == null
            ? CoursesLocalizations.of(context)!.courses_addQuestion
            : CoursesLocalizations.of(context)!.courses_editQuestion,
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('questionText'),
                  controller: _question,
                  decoration: InputDecoration(
                    labelText: CoursesLocalizations.of(
                      context,
                    )!.courses_question,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? CoursesLocalizations.of(context)!.courses_enterQuestion
                      : null,
                ),
                const SizedBox(height: 12),
                RadioGroup<int>(
                  groupValue: _correct,
                  onChanged: (v) => setState(() => _correct = v ?? _correct),
                  child: Column(
                    children: [
                      for (var i = 0; i < _optionCount; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Radio<int>(
                                key: Key('questionCorrect$i'),
                                value: i,
                              ),
                              Expanded(
                                child: TextFormField(
                                  key: Key('questionOption$i'),
                                  controller: _options[i],
                                  decoration: InputDecoration(
                                    labelText: CoursesLocalizations.of(
                                      context,
                                    )!.courses_optionN((i + 1).toString()),
                                    border: const OutlineInputBorder(),
                                  ),
                                  // two options at least; the correct one filled
                                  validator: (v) =>
                                      (i < 2 || i == _correct) &&
                                          (v == null || v.trim().isEmpty)
                                      ? CoursesLocalizations.of(
                                          context,
                                        )!.courses_enterThisOption
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  CoursesLocalizations.of(context)!.courses_selectCorrectAnswer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('questionExplanation'),
                  controller: _explanation,
                  decoration: InputDecoration(
                    labelText: CoursesLocalizations.of(
                      context,
                    )!.courses_explanationShown,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(CoursesLocalizations.of(context)!.courses_cancel),
        ),
        ElevatedButton(
          key: const Key('saveQuestion'),
          onPressed: _save,
          child: Text(CoursesLocalizations.of(context)!.courses_save),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // drop empty options, keeping the correct one pointed at
    final options = <String>[];
    var correct = 0;
    for (var i = 0; i < _optionCount; i++) {
      final text = _options[i].text.trim();
      if (text.isEmpty) continue;
      if (i == _correct) correct = options.length;
      options.add(text);
    }
    Navigator.pop(
      context,
      CourseQuizQuestion(
        questionId: widget.question?.questionId,
        moduleId: widget.moduleId,
        sequenceNum: widget.question?.sequenceNum,
        question: _question.text.trim(),
        options: options,
        correctIndex: correct,
        explanation: _explanation.text.trim().isEmpty
            ? null
            : _explanation.text.trim(),
      ),
    );
  }
}
