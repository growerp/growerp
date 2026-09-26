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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_bloc.dart';
import '../../course_ai/bloc/course_ai_bloc.dart';
import '../../course_ai/views/ai_key_needed_dialog.dart';
import 'course_participants_view.dart';
import 'quiz_editor_dialog.dart';
import 'slides_editor_dialog.dart';
import '../../documents/course_pdfs.dart';
import '../../viewer/views/course_viewer.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';

class CourseDialog extends StatefulWidget {
  final Course? course;

  const CourseDialog({super.key, this.course});

  @override
  State<CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<CourseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _objectivesController;
  late TextEditingController _audienceController;
  late CourseAiBloc _aiBloc;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  CourseDifficulty _selectedDifficulty = CourseDifficulty.beginner;
  CourseStatus _selectedStatus = CourseStatus.draft;

  bool get isEdit => widget.course?.courseId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.course?.description ?? '',
    );
    _objectivesController = TextEditingController(
      text: widget.course?.objectives ?? '',
    );
    _audienceController = TextEditingController(
      text: widget.course?.audience ?? '',
    );
    _durationController = TextEditingController(
      text: widget.course?.estimatedDuration?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.course?.price?.toStringAsFixed(2) ?? '',
    );
    _selectedDifficulty =
        widget.course?.difficulty ?? CourseDifficulty.beginner;
    _selectedStatus = widget.course?.status ?? CourseStatus.draft;
    // load the course as selectedCourse: module/lesson creates refresh it, so
    // new modules and lessons show up in this dialog right away
    if (isEdit) {
      context.read<CourseBloc>().add(CourseGetDetail(widget.course!.courseId!));
    }
    // follow an AI job that is still writing this course
    _aiBloc = CourseAiBloc(restClient: context.read<RestClient>());
    if (isEdit) _aiBloc.add(CourseAiWatch(widget.course!.courseId!));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _objectivesController.dispose();
    _audienceController.dispose();
    _aiBloc.close();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: isEdit ? 'Edit Course' : 'New Course',
        width: 600,
        height: MediaQuery.of(context).size.height * 0.85,
        child: ScaffoldMessenger(
          child: DefaultTabController(
            length: isEdit ? 2 : 1,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  if (isEdit)
                    TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      tabs: const [
                        Tab(icon: Icon(Icons.edit_note), text: 'Details'),
                        Tab(icon: Icon(Icons.group), text: 'Participants'),
                      ],
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(),
                        if (isEdit)
                          CourseParticipantsView(
                            courseId: widget.course!.courseId!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildActionButtons(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildObjectivesField(),
            const SizedBox(height: 16),
            _buildAudienceField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDifficultyDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildDurationField()),
              ],
            ),
            const SizedBox(height: 16),
            _buildProductPriceRow(),
            // new courses start as draft: publish once the content is there
            if (isEdit) ...[const SizedBox(height: 16), _buildStatusDropdown()],
            const SizedBox(height: 24),
            if (isEdit) ...[_buildModulesSection(), const SizedBox(height: 16)],
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      key: const Key('courseTitle'),
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Course Title *',
        hintText: 'e.g., GrowERP Field Service Masterclass',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a course title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      key: const Key('courseDescription'),
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Brief overview of what this course covers',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildObjectivesField() {
    return TextFormField(
      key: const Key('courseObjectives'),
      controller: _objectivesController,
      decoration: const InputDecoration(
        labelText: 'Learning Objectives',
        hintText: 'What will learners be able to do after this course?',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildAudienceField() {
    return TextFormField(
      key: const Key('courseAudience'),
      controller: _audienceController,
      decoration: const InputDecoration(
        labelText: 'Audience',
        hintText: 'Who is this course for? The AI writes for them.',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<CourseDifficulty>(
      key: const Key('courseDifficulty'),
      initialValue: _selectedDifficulty,
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
      ),
      items: CourseDifficulty.values.map((difficulty) {
        return DropdownMenuItem(
          value: difficulty,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: _getDifficultyColor(difficulty),
              ),
              const SizedBox(width: 8),
              Text(_getDifficultyLabel(difficulty)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedDifficulty = value);
        }
      },
    );
  }

  /// Only published courses are offered to learners (website and academy app)
  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<CourseStatus>(
      key: const Key('courseStatus'),
      initialValue: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: CourseStatus.draft, child: Text('Draft')),
        DropdownMenuItem(
          value: CourseStatus.published,
          child: Text('Published'),
        ),
        DropdownMenuItem(value: CourseStatus.archived, child: Text('Archived')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _selectedStatus = value);
      },
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      key: const Key('courseDuration'),
      controller: _durationController,
      decoration: const InputDecoration(
        labelText: 'Duration (minutes)',
        hintText: 'e.g., 60',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildProductPriceRow() {
    final productPseudoId = widget.course?.productPseudoId;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            key: const Key('courseProductPseudoId'),
            readOnly: true,
            initialValue: productPseudoId ?? '',
            decoration: const InputDecoration(
              labelText: 'Product ID',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            key: const Key('coursePrice'),
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price',
              hintText: '0.00',
              prefixText: '\$',
              border: OutlineInputBorder(),
              helperText: 'Leave empty for free',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (Decimal.tryParse(value) == null) {
                  return 'Enter a valid price';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModulesSection() {
    final selected = context.watch<CourseBloc>().state.selectedCourse;
    final modules =
        (selected?.courseId == widget.course?.courseId
            ? selected?.modules
            : null) ??
        widget.course?.modules ??
        [];
    // the course the documents are made of: as reloaded when it is this one
    final docCourse = selected?.courseId == widget.course?.courseId
        ? selected!
        : widget.course!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // wraps: on a phone the buttons do not fit next to the title
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              CoursesLocalizations.of(
                context,
              )!.courses_modulesModuleslength(modules.length.toString()),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              children: [
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('aiWriteLessons'),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Write lessons with AI'),
                    onPressed: () => _writeLessonsWithAi(null),
                  ),
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('aiWriteQuizzes'),
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Quizzes with AI'),
                    onPressed: () => _writeQuizzesWithAi(null),
                  ),
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('aiWriteSlides'),
                    icon: const Icon(Icons.slideshow),
                    label: const Text('Slides with AI'),
                    onPressed: () => _writeSlidesWithAi(null),
                  ),
                if (modules.any((m) => m.slides?.isNotEmpty ?? false))
                  TextButton.icon(
                    key: const Key('courseSlidesPdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Slide deck'),
                    onPressed: () => _showSlidesPdf(docCourse),
                  ),
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('courseWorkbookPdf'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Workbook'),
                    onPressed: () => _showWorkbookPdf(docCourse),
                  ),
                TextButton.icon(
                  key: const Key('addModule'),
                  icon: const Icon(Icons.add),
                  label: Text(
                    CoursesLocalizations.of(context)!.courses_addModule,
                  ),
                  onPressed: () => _showAddModuleDialog(),
                ),
              ],
            ),
          ],
        ),
        _buildAiJobBanner(),
        const Divider(),
        if (modules.isEmpty)
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              CoursesLocalizations.of(context)!.courses_noModulesYetAdd,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return ExpansionTile(
                key: Key('module$index'),
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(module.title),
                subtitle: Text(
                  CoursesLocalizations.of(
                    context,
                  )!.courses_modulelessonslength0Lessons(
                    (module.lessons?.length ?? 0).toString(),
                  ),
                ),
                children: [
                  if (module.lessons != null)
                    ...module.lessons!.map(
                      (lesson) => ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 72,
                          right: 16,
                        ),
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(lesson.title),
                        subtitle: lesson.estimatedDuration != null
                            ? Text(
                                CoursesLocalizations.of(
                                  context,
                                )!.courses_lessonestimateddurationMin(
                                  lesson.estimatedDuration.toString(),
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          key: Key('aiLesson${lesson.lessonId}'),
                          icon: const Icon(Icons.auto_awesome),
                          tooltip: 'Write this lesson with AI',
                          onPressed: () => _writeLessonsWithAi(lesson),
                        ),
                      ),
                    ),
                  ListTile(
                    key: Key('addLesson$index'),
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: const Icon(Icons.add, color: Colors.blue),
                    title: Text(
                      CoursesLocalizations.of(context)!.courses_addLesson,
                      style: TextStyle(color: Colors.blue),
                    ),
                    onTap: () => _showAddLessonDialog(module),
                  ),
                  ListTile(
                    key: Key('moduleQuiz$index'),
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: const Icon(Icons.quiz_outlined),
                    title: Text(
                      'Quiz: ${module.quizQuestionCount ?? 0} questions',
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<CourseBloc>(),
                        child: QuizEditorDialog(moduleId: module.moduleId!),
                      ),
                    ),
                    trailing: IconButton(
                      key: Key('aiQuiz$index'),
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: 'Write this quiz with AI',
                      onPressed: () => _writeQuizzesWithAi(module),
                    ),
                  ),
                  ListTile(
                    key: Key('moduleSlides$index'),
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: const Icon(Icons.slideshow),
                    title: Text('Slides: ${module.slides?.length ?? 0}'),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<CourseBloc>(),
                        child: SlidesEditorDialog(moduleId: module.moduleId!),
                      ),
                    ),
                    trailing: IconButton(
                      key: Key('aiSlides$index'),
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: 'Make these slides with AI',
                      onPressed: () => _writeSlidesWithAi(module),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  /// Progress of a running AI job; reloads the course when it is done
  Widget _buildAiJobBanner() {
    return BlocConsumer<CourseAiBloc, CourseAiState>(
      bloc: _aiBloc,
      listener: (context, state) {
        if (state.status == CourseAiStatus.success) {
          context.read<CourseBloc>().add(
            CourseGetDetail(widget.course!.courseId!),
          );
          HelperFunctions.showMessage(
            context,
            state.message ?? 'Done',
            Colors.green,
          );
        }
        // lessons written before the tokens ran out are kept: show them
        if (state.status == CourseAiStatus.failure &&
            (state.job?.needsAiKey ?? false)) {
          context.read<CourseBloc>().add(
            CourseGetDetail(widget.course!.courseId!),
          );
          showAiKeyNeededDialog(context, state.message);
        } else if (state.status == CourseAiStatus.failure) {
          HelperFunctions.showMessage(
            context,
            state.message ?? 'The AI job failed',
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        if (state.status != CourseAiStatus.running) {
          return const SizedBox.shrink();
        }
        final percent = state.job?.progressPercent ?? 0;
        return Padding(
          key: const Key('aiJobBanner'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: percent > 0 ? percent / 100 : null,
              ),
              const SizedBox(height: 4),
              Text(
                state.job?.statusMessage ?? 'Starting',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Writes all lessons ([lesson] null) or one lesson from its brief/text,
  /// the outline and the course sources. Replaces the current lesson text.
  Future<void> _writeLessonsWithAi(CourseLesson? lesson) async {
    if (_aiBloc.state.status == CourseAiStatus.running) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          lesson == null ? 'Write all lessons with AI' : 'Write lesson with AI',
        ),
        content: Text(
          lesson == null
              ? 'The AI rewrites the text of every lesson, using the lesson '
                    'text as the brief. This can take several minutes.'
              : 'The AI rewrites "${lesson.title}", using its current text as '
                    'the brief.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('aiWriteConfirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Write'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _aiBloc.add(
      CourseAiStart({
        'jobType': 'LESSONS',
        'courseId': widget.course!.courseId,
        if (lesson != null) 'lessonIds': [lesson.lessonId],
      }),
    );
  }

  Future<void> _writeQuizzesWithAi(CourseModule? module) => _runModuleAiJob(
    jobType: 'QUIZ',
    module: module,
    title: 'Write quizzes with AI',
    what: module == null
        ? 'a quiz for every module from its lessons, replacing the '
              'questions there are now.'
        : 'the quiz of "${module.title}" from its lessons, replacing the '
              'questions there are now.',
    confirmKey: 'aiQuizConfirm',
  );

  Future<void> _writeSlidesWithAi(CourseModule? module) => _runModuleAiJob(
    jobType: 'SLIDES',
    module: module,
    title: 'Make slides with AI',
    what: module == null
        ? 'the slides of every module from its lessons, with speaker notes, '
              'replacing the slides there are now.'
        : 'the slides of "${module.title}" from its lessons, with speaker '
              'notes, replacing the slides there are now.',
    confirmKey: 'aiSlidesConfirm',
  );

  /// Runs an AI job on every module ([module] null) or on one module
  Future<void> _runModuleAiJob({
    required String jobType,
    required CourseModule? module,
    required String title,
    required String what,
    required String confirmKey,
  }) async {
    if (_aiBloc.state.status == CourseAiStatus.running) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text('The AI writes $what'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: Key(confirmKey),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Write'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _aiBloc.add(
      CourseAiStart({
        'jobType': jobType,
        'courseId': widget.course!.courseId,
        if (module != null) 'moduleIds': [module.moduleId],
      }),
    );
  }

  /// Course documents from the course as loaded in this dialog
  void _showSlidesPdf(Course course) => showPdfDialog(
    context,
    key: const Key('slidesPdfDialog'),
    title: 'Slides',
    fileName: 'slides-${course.title}.pdf',
    pageFormat: slidePageFormat,
    build: (format) => slidesPdf(course, course.modules ?? [], format),
  );

  void _showWorkbookPdf(Course course) => showPdfDialog(
    context,
    key: const Key('workbookPdfDialog'),
    title: 'Workbook',
    fileName: 'workbook-${course.title}.pdf',
    pageFormat: PdfPageFormat.a4,
    build: (format) => workbookPdf(course, format),
  );

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEdit)
            TextButton(
              key: const Key('deleteCourse'),
              onPressed: _deleteCourse,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          if (isEdit) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              key: const Key('previewCourse'),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview'),
              onPressed: _previewCourse,
            ),
          ],
          const Spacer(),
          TextButton(
            key: const Key('cancelCourse'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('saveCourse'),
            onPressed: _saveCourse,
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return Colors.green;
      case CourseDifficulty.intermediate:
        return Colors.orange;
      case CourseDifficulty.advanced:
        return Colors.red;
    }
  }

  String _getDifficultyLabel(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return 'Beginner';
      case CourseDifficulty.intermediate:
        return 'Intermediate';
      case CourseDifficulty.advanced:
        return 'Advanced';
    }
  }

  void _saveCourse() {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text.trim();
    final course = Course(
      courseId: widget.course?.courseId,
      pseudoId: widget.course?.pseudoId,
      productId: widget.course?.productId,
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      objectives: _objectivesController.text.isNotEmpty
          ? _objectivesController.text
          : null,
      audience: _audienceController.text.isNotEmpty
          ? _audienceController.text
          : null,
      difficulty: _selectedDifficulty,
      status: _selectedStatus,
      estimatedDuration: _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text)
          : null,
      price: priceText.isNotEmpty ? Decimal.parse(priceText) : null,
    );

    if (isEdit) {
      context.read<CourseBloc>().add(CourseUpdate(course));
    } else {
      context.read<CourseBloc>().add(CourseCreate(course));
    }

    Navigator.pop(context);
  }

  /// Shows the saved course as a learner sees it; staff get full lesson
  /// content, drafts included
  void _previewCourse() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseViewer(courseId: widget.course!.courseId!),
      ),
    );
  }

  void _deleteCourse() {
    if (widget.course == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CoursesLocalizations.of(context)!.courses_deleteCourse),
        content: Text(
          CoursesLocalizations.of(
            context,
          )!.courses_areYouSureYou(widget.course!.title.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CourseBloc>().add(CourseDelete(widget.course!));
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddModuleDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(CoursesLocalizations.of(context)!.courses_addModule),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('moduleTitle'),
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Module Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('moduleDescription'),
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('saveModule'),
            onPressed: () {
              if (titleController.text.isEmpty) return;

              context.read<CourseBloc>().add(
                CourseModuleCreate(
                  courseId: widget.course!.courseId!,
                  module: CourseModule(
                    title: titleController.text,
                    description: descController.text.isNotEmpty
                        ? descController.text
                        : null,
                  ),
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(CourseModule module) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          CoursesLocalizations.of(
            context,
          )!.courses_addLessonToModuletitle(module.title.toString()),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('lessonTitle'),
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Lesson Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('lessonContent'),
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content (Markdown)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('saveLesson'),
            onPressed: () {
              if (titleController.text.isEmpty) return;

              context.read<CourseBloc>().add(
                CourseLessonCreate(
                  moduleId: module.moduleId!,
                  lesson: CourseLesson(
                    title: titleController.text,
                    content: contentController.text.isNotEmpty
                        ? contentController.text
                        : null,
                  ),
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
