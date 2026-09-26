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

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/course_ai_bloc.dart';
import 'ai_key_needed_dialog.dart';

/// Step 1 of creating a course with AI: title, audience, curriculum and
/// source material. The AI then designs the outline (modules with lesson
/// briefs) as a draft course; the dialog pops with its courseId so the author
/// can review it in the course dialog before the lessons are written.
class AiCourseWizardDialog extends StatelessWidget {
  const AiCourseWizardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseAiBloc(restClient: context.read<RestClient>()),
      child: const _AiCourseWizardView(),
    );
  }
}

class _AiCourseWizardView extends StatefulWidget {
  const _AiCourseWizardView();

  @override
  State<_AiCourseWizardView> createState() => _AiCourseWizardViewState();
}

class _AiCourseWizardViewState extends State<_AiCourseWizardView> {
  static const _maxFileBytes = 10 * 1024 * 1024;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _audienceController = TextEditingController();
  final _curriculumController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlsController = TextEditingController();
  final List<PlatformFile> _files = [];
  CourseDifficulty _difficulty = CourseDifficulty.beginner;
  bool _useKnowledgeBase = false;

  @override
  void dispose() {
    _titleController.dispose();
    _audienceController.dispose();
    _curriculumController.dispose();
    _notesController.dispose();
    _urlsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseAiBloc, CourseAiState>(
      listener: (context, state) {
        if (state.status == CourseAiStatus.success) {
          Navigator.of(context).pop(state.job?.courseId);
        }
        if (state.status == CourseAiStatus.failure &&
            (state.job?.needsAiKey ?? false)) {
          // the form is still filled in: after saving a key just press again
          showAiKeyNeededDialog(context, state.message);
        } else if (state.status == CourseAiStatus.failure) {
          HelperFunctions.showMessage(
            context,
            state.message ?? 'The AI could not create the course',
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        final running = state.status == CourseAiStatus.running;
        return Dialog(
          key: const Key('AiCourseWizardDialog'),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: popUp(
            context: context,
            title: 'Create course with AI',
            width: 600,
            height: MediaQuery.of(context).size.height * 0.85,
            child: running ? _progress(state.job) : _form(),
          ),
        );
      },
    );
  }

  Widget _progress(CourseAiJob? job) {
    final percent = job?.progressPercent ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              key: const Key('aiCourseProgress'),
              value: percent > 0 ? percent / 100 : null,
            ),
            const SizedBox(height: 16),
            Text(
              job?.statusMessage ?? 'Starting',
              key: const Key('aiCourseStatus'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This takes a minute or two. The course is created as a draft.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    key: const Key('aiCourseTitle'),
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Course Title *',
                      hintText: 'e.g., Bookkeeping basics for freelancers',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a course title'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('aiCourseAudience'),
                    controller: _audienceController,
                    decoration: const InputDecoration(
                      labelText: 'Audience',
                      hintText: 'Who is this course for, what do they know?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CourseDifficulty>(
                    key: const Key('aiCourseDifficulty'),
                    initialValue: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: CourseDifficulty.beginner,
                        child: Text('Beginner'),
                      ),
                      DropdownMenuItem(
                        value: CourseDifficulty.intermediate,
                        child: Text('Intermediate'),
                      ),
                      DropdownMenuItem(
                        value: CourseDifficulty.advanced,
                        child: Text('Advanced'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _difficulty = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('aiCourseCurriculum'),
                    controller: _curriculumController,
                    decoration: const InputDecoration(
                      labelText: 'Curriculum',
                      hintText:
                          'Topics in order, one per line. Leave empty to let the AI propose them.',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Additional resources',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('aiCourseNotes'),
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Anything the AI should know or use',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('aiCourseUrls'),
                    controller: _urlsController,
                    decoration: const InputDecoration(
                      labelText: 'Web pages',
                      hintText: 'One URL per line',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      for (final url in _urls(value ?? '')) {
                        final uri = Uri.tryParse(url);
                        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                          return 'Not a valid URL: $url';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('aiCourseAddFile'),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add documents'),
                        onPressed: _pickFiles,
                      ),
                      for (final file in _files)
                        InputChip(
                          label: Text(file.name),
                          onDeleted: () => setState(() => _files.remove(file)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'pdf, docx, md or txt; documents are also added to the company knowledge base',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('aiCourseUseKb'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use the company knowledge base'),
                    value: _useKnowledgeBase,
                    onChanged: (value) =>
                        setState(() => _useKnowledgeBase = value),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('aiCourseCancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: const Key('aiCourseGenerate'),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Create outline'),
                  onPressed: _generate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _urls(String text) => text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  Future<void> _pickFiles() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx', 'md', 'markdown', 'txt'],
      );
      final accepted = <PlatformFile>[];
      final tooBig = <String>[];
      for (final f in picked) {
        if (await f.length() > _maxFileBytes) {
          tooBig.add(f.name);
        } else {
          accepted.add(f);
        }
      }
      if (!mounted) return;
      if (tooBig.isNotEmpty) {
        HelperFunctions.showMessage(
          context,
          'Skipped, larger than 10MB: ${tooBig.join(', ')}',
          Colors.orange,
        );
      }
      setState(() => _files.addAll(accepted));
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Could not open file: $e',
          Colors.red,
        );
      }
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final files = <Map<String, String>>[];
    for (final file in _files) {
      files.add({
        'fileName': file.name,
        'base64': base64Encode(await file.readAsBytes()),
      });
    }
    if (!mounted) return;
    context.read<CourseAiBloc>().add(
      CourseAiStart({
        'jobType': 'OUTLINE',
        'title': _titleController.text.trim(),
        'audience': _audienceController.text.trim(),
        'difficulty': _difficulty.name.toUpperCase(),
        'curriculum': _curriculumController.text.trim(),
        'notes': _notesController.text.trim(),
        'urls': _urls(_urlsController.text),
        'files': files,
        'useKnowledgeBase': _useKnowledgeBase,
      }),
    );
  }
}
