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

/// The exercises of one module, or with [moduleId] null the capstone
/// project(s) of the course: add, edit, delete. Shows the course as reloaded
/// by the [CourseBloc] after every change.
class ExerciseEditorDialog extends StatelessWidget {
  final String courseId;
  final String? moduleId;

  const ExerciseEditorDialog({
    super.key,
    required this.courseId,
    this.moduleId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final course = context.select<CourseBloc, Course?>(
      (bloc) => bloc.state.selectedCourse,
    );
    final module = course?.modules
        ?.where((m) => m.moduleId == moduleId)
        .firstOrNull;
    final exercises =
        (moduleId == null ? course?.exercises : module?.exercises) ?? [];
    return Dialog(
      key: const Key('ExerciseEditorDialog'),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: moduleId == null
            ? l10n.courses_capstoneProject
            : l10n.courses_exercisesOf(module?.title ?? ''),
        width: 600,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: exercises.isEmpty
                  ? Center(child: Text(l10n.courses_noExercisesYet))
                  : ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ListTile(
                          key: Key('exerciseItem$index'),
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(exercise.title),
                          subtitle: Text(
                            _typeLabel(context, exercise.exerciseType),
                          ),
                          onTap: () => _edit(context, module, exercise),
                          trailing: IconButton(
                            key: Key('deleteExercise$index'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => context.read<CourseBloc>().add(
                              CourseExerciseDelete(exercise.exerciseId!),
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
                    key: const Key('addExercise'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.courses_addExercise),
                    onPressed: () => _edit(context, module, null),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const Key('closeExercises'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.courses_close),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    CourseModule? module,
    CourseExercise? exercise,
  ) async {
    final saved = await showDialog<CourseExercise>(
      context: context,
      builder: (_) => _ExerciseDialog(
        courseId: courseId,
        module: module,
        exercise: exercise,
      ),
    );
    if (saved != null && context.mounted) {
      context.read<CourseBloc>().add(CourseExerciseSave(saved));
    }
  }
}

String _typeLabel(BuildContext context, String? type) {
  final l10n = CoursesLocalizations.of(context)!;
  switch (type) {
    case CourseExerciseType.code:
      return l10n.courses_exerciseTypeCode;
    case CourseExerciseType.project:
      return l10n.courses_exerciseTypeProject;
    default:
      return l10n.courses_exerciseTypeText;
  }
}

class _ExerciseDialog extends StatefulWidget {
  final String courseId;
  final CourseModule? module;
  final CourseExercise? exercise;

  const _ExerciseDialog({
    required this.courseId,
    this.module,
    this.exercise,
  });

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _prompt;
  late final TextEditingController _rubric;
  late String _type;
  String? _lessonId;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _title = TextEditingController(text: e?.title ?? '');
    _prompt = TextEditingController(text: e?.prompt ?? '');
    _rubric = TextEditingController(text: e?.rubric ?? '');
    _type =
        e?.exerciseType ??
        (widget.module == null
            ? CourseExerciseType.project
            : CourseExerciseType.text);
    _lessonId = e?.lessonId;
  }

  @override
  void dispose() {
    _title.dispose();
    _prompt.dispose();
    _rubric.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final lessons = widget.module?.lessons ?? [];
    return AlertDialog(
      title: Text(
        widget.exercise == null
            ? l10n.courses_addExercise
            : l10n.courses_editExercise,
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
                  key: const Key('exerciseTitle'),
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: l10n.courses_titleLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.courses_enterTitle
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('exerciseType'),
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: l10n.courses_exerciseType,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final type in [
                      CourseExerciseType.text,
                      CourseExerciseType.code,
                      CourseExerciseType.project,
                    ])
                      DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(context, type)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                if (lessons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: const Key('exerciseLesson'),
                    initialValue: _lessonId,
                    decoration: InputDecoration(
                      labelText: l10n.courses_practicesLesson,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('-'),
                      ),
                      for (final lesson in lessons)
                        DropdownMenuItem<String?>(
                          value: lesson.lessonId,
                          child: Text(
                            lesson.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _lessonId = v),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('exercisePrompt'),
                  controller: _prompt,
                  decoration: InputDecoration(
                    labelText: l10n.courses_exerciseTask,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 4,
                  maxLines: 10,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.courses_enterTheTask
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('exerciseRubric'),
                  controller: _rubric,
                  decoration: InputDecoration(
                    labelText: l10n.courses_exerciseRubric,
                    helperText: l10n.courses_exerciseRubricHelp,
                    helperMaxLines: 2,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 8,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.courses_cancel),
        ),
        ElevatedButton(
          key: const Key('saveExercise'),
          onPressed: _save,
          child: Text(l10n.courses_save),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CourseExercise(
        exerciseId: widget.exercise?.exerciseId,
        courseId: widget.courseId,
        moduleId: widget.module?.moduleId,
        lessonId: _lessonId,
        sequenceNum: widget.exercise?.sequenceNum,
        exerciseType: _type,
        title: _title.text.trim(),
        prompt: _prompt.text.trim(),
        rubric: _rubric.text.trim(),
      ),
    );
  }
}
