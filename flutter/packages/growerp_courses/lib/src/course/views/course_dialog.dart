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
import '../../documents/backend_url.dart';
import '../../documents/course_pdfs.dart';
import '../../documents/course_video_dialog.dart';
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
        title: isEdit
            ? CoursesLocalizations.of(context)!.courses_editCourse
            : CoursesLocalizations.of(context)!.courses_newCourse,
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
                      tabs: [
                        Tab(
                          icon: Icon(Icons.edit_note),
                          text: CoursesLocalizations.of(
                            context,
                          )!.courses_details,
                        ),
                        Tab(
                          icon: Icon(Icons.group),
                          text: CoursesLocalizations.of(
                            context,
                          )!.courses_participants,
                        ),
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
            if (isEdit) _buildCover(),
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

  /// The cover image as shown on the website, once there is one
  Widget _buildCover() {
    final selected = context.watch<CourseBloc>().state.selectedCourse;
    final url = selected?.courseId == widget.course?.courseId
        ? selected?.coverImageUrl
        : widget.course?.coverImageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('courseCover'),
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: BackendImage(
            url: url,
            fit: BoxFit.cover,
            fallback: const Center(child: Icon(Icons.image_outlined)),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      key: const Key('courseTitle'),
      controller: _titleController,
      decoration: InputDecoration(
        labelText: CoursesLocalizations.of(
          context,
        )!.courses_courseTitleRequired,
        hintText: CoursesLocalizations.of(context)!.courses_courseTitleHint,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return CoursesLocalizations.of(context)!.courses_enterCourseTitle;
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      key: const Key('courseDescription'),
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: CoursesLocalizations.of(context)!.courses_description,
        hintText: CoursesLocalizations.of(context)!.courses_descriptionHint,
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildObjectivesField() {
    return TextFormField(
      key: const Key('courseObjectives'),
      controller: _objectivesController,
      decoration: InputDecoration(
        labelText: CoursesLocalizations.of(context)!.courses_learningObjectives,
        hintText: CoursesLocalizations.of(context)!.courses_objectivesHint,
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildAudienceField() {
    return TextFormField(
      key: const Key('courseAudience'),
      controller: _audienceController,
      decoration: InputDecoration(
        labelText: CoursesLocalizations.of(context)!.courses_audience,
        hintText: CoursesLocalizations.of(context)!.courses_audienceHint,
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<CourseDifficulty>(
      key: const Key('courseDifficulty'),
      initialValue: _selectedDifficulty,
      decoration: InputDecoration(
        labelText: CoursesLocalizations.of(context)!.courses_difficulty,
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
      decoration: InputDecoration(
        labelText: CoursesLocalizations.of(context)!.courses_status,
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: CourseStatus.draft,
          child: Text(CoursesLocalizations.of(context)!.courses_draft),
        ),
        DropdownMenuItem(
          value: CourseStatus.published,
          child: Text(CoursesLocalizations.of(context)!.courses_published),
        ),
        DropdownMenuItem(
          value: CourseStatus.archived,
          child: Text(CoursesLocalizations.of(context)!.courses_archived),
        ),
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
      decoration: InputDecoration(
        labelText: CoursesLocalizations.of(context)!.courses_durationMinutes,
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
            decoration: InputDecoration(
              labelText: CoursesLocalizations.of(context)!.courses_productId,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            key: const Key('coursePrice'),
            controller: _priceController,
            decoration: InputDecoration(
              labelText: CoursesLocalizations.of(context)!.courses_priceLabel,
              hintText: '0.00',
              prefixText: '\$',
              border: OutlineInputBorder(),
              helperText: CoursesLocalizations.of(
                context,
              )!.courses_leaveEmptyForFree,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (Decimal.tryParse(value) == null) {
                  return CoursesLocalizations.of(
                    context,
                  )!.courses_enterValidPrice;
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
                    label: Text(
                      CoursesLocalizations.of(
                        context,
                      )!.courses_writeLessonsWithAi,
                    ),
                    onPressed: () => _writeLessonsWithAi(null),
                  ),
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('aiWriteQuizzes'),
                    icon: const Icon(Icons.quiz_outlined),
                    label: Text(
                      CoursesLocalizations.of(context)!.courses_quizzesWithAi,
                    ),
                    onPressed: () => _writeQuizzesWithAi(null),
                  ),
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('aiWriteSlides'),
                    icon: const Icon(Icons.slideshow),
                    label: Text(
                      CoursesLocalizations.of(context)!.courses_slidesWithAi,
                    ),
                    onPressed: () => _writeSlidesWithAi(null),
                  ),
                if (modules.any((m) => m.slides?.isNotEmpty ?? false))
                  TextButton.icon(
                    key: const Key('aiWriteVideos'),
                    icon: const Icon(Icons.ondemand_video),
                    label: Text(
                      CoursesLocalizations.of(
                        context,
                      )!.courses_videosFromSlides,
                    ),
                    onPressed: () => _makeVideos(null),
                  ),
                if (modules.any((m) => m.slides?.isNotEmpty ?? false))
                  TextButton.icon(
                    key: const Key('courseSlidesPdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(
                      CoursesLocalizations.of(context)!.courses_slideDeck,
                    ),
                    onPressed: () => _showSlidesPdf(docCourse),
                  ),
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('aiPromo'),
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text(
                      CoursesLocalizations.of(context)!.courses_promoPackWithAi,
                    ),
                    onPressed: () => _runModuleAiJob(
                      jobType: 'PROMO',
                      module: null,
                      title: CoursesLocalizations.of(
                        context,
                      )!.courses_promoPackWithAi,
                      message: CoursesLocalizations.of(
                        context,
                      )!.courses_promoPackMessage,
                      confirmKey: 'aiPromoConfirm',
                    ),
                  ),
                if (modules.isNotEmpty)
                  TextButton.icon(
                    key: const Key('courseWorkbookPdf'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(
                      CoursesLocalizations.of(context)!.courses_workbook,
                    ),
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
                          tooltip: CoursesLocalizations.of(
                            context,
                          )!.courses_writeThisLessonWithAi,
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
                      CoursesLocalizations.of(context)!.courses_quizQuestions(
                        (module.quizQuestionCount ?? 0).toString(),
                      ),
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
                      tooltip: CoursesLocalizations.of(
                        context,
                      )!.courses_writeThisQuizWithAi,
                      onPressed: () => _writeQuizzesWithAi(module),
                    ),
                  ),
                  ListTile(
                    key: Key('moduleSlides$index'),
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: const Icon(Icons.slideshow),
                    title: Text(
                      CoursesLocalizations.of(context)!.courses_slidesCount(
                        (module.slides?.length ?? 0).toString(),
                      ),
                    ),
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
                      tooltip: CoursesLocalizations.of(
                        context,
                      )!.courses_makeTheseSlidesWithAi,
                      onPressed: () => _writeSlidesWithAi(module),
                    ),
                  ),
                  if (module.slides?.isNotEmpty ?? false)
                    ListTile(
                      key: Key('moduleVideo$index'),
                      contentPadding: const EdgeInsets.only(
                        left: 72,
                        right: 16,
                      ),
                      leading: const Icon(Icons.ondemand_video),
                      title: Text(
                        module.videoUrl == null
                            ? CoursesLocalizations.of(
                                context,
                              )!.courses_videoNone
                            : CoursesLocalizations.of(
                                context,
                              )!.courses_videoReady,
                      ),
                      onTap: module.videoUrl == null
                          ? null
                          : () => showCourseVideo(
                              context,
                              title: module.title,
                              videoUrl: module.videoUrl!,
                            ),
                      trailing: IconButton(
                        key: Key('aiVideo$index'),
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: CoursesLocalizations.of(
                          context,
                        )!.courses_makeThisVideo,
                        onPressed: () => _makeVideos(module),
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
            state.message ?? CoursesLocalizations.of(context)!.courses_done,
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
            state.message ??
                CoursesLocalizations.of(context)!.courses_aiJobFailed,
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
                state.job?.statusMessage ??
                    CoursesLocalizations.of(context)!.courses_starting,
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
          lesson == null
              ? CoursesLocalizations.of(context)!.courses_writeAllLessonsWithAi
              : CoursesLocalizations.of(context)!.courses_writeLessonWithAi,
        ),
        content: Text(
          lesson == null
              ? CoursesLocalizations.of(
                  context,
                )!.courses_rewriteAllLessonsMessage
              : CoursesLocalizations.of(
                  context,
                )!.courses_rewriteLessonMessage(lesson.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(CoursesLocalizations.of(context)!.courses_cancel),
          ),
          ElevatedButton(
            key: const Key('aiWriteConfirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(CoursesLocalizations.of(context)!.courses_write),
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
    title: CoursesLocalizations.of(context)!.courses_writeQuizzesWithAi,
    message: module == null
        ? CoursesLocalizations.of(context)!.courses_quizzesAllMessage
        : CoursesLocalizations.of(
            context,
          )!.courses_quizModuleMessage(module.title),
    confirmKey: 'aiQuizConfirm',
  );

  Future<void> _writeSlidesWithAi(CourseModule? module) => _runModuleAiJob(
    jobType: 'SLIDES',
    module: module,
    title: CoursesLocalizations.of(context)!.courses_makeSlidesWithAi,
    message: module == null
        ? CoursesLocalizations.of(context)!.courses_slidesAllMessage
        : CoursesLocalizations.of(
            context,
          )!.courses_slidesModuleMessage(module.title),
    confirmKey: 'aiSlidesConfirm',
  );

  Future<void> _makeVideos(CourseModule? module) => _runModuleAiJob(
    jobType: 'VIDEO',
    module: module,
    title: CoursesLocalizations.of(context)!.courses_makeVideos,
    message: module == null
        ? CoursesLocalizations.of(context)!.courses_videosAllMessage
        : CoursesLocalizations.of(
            context,
          )!.courses_videoModuleMessage(module.title),
    confirmKey: 'aiVideoConfirm',
  );

  /// Runs an AI job on every module ([module] null) or on one module
  Future<void> _runModuleAiJob({
    required String jobType,
    required CourseModule? module,
    required String title,
    required String message,
    required String confirmKey,
  }) async {
    if (_aiBloc.state.status == CourseAiStatus.running) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(CoursesLocalizations.of(context)!.courses_cancel),
          ),
          ElevatedButton(
            key: Key(confirmKey),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(CoursesLocalizations.of(context)!.courses_write),
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
    title: CoursesLocalizations.of(context)!.courses_slides,
    fileName: 'slides-${course.title}.pdf',
    pageFormat: slidePageFormat,
    build: (format) => slidesPdf(
      CoursesLocalizations.of(context)!,
      course,
      course.modules ?? [],
      format,
    ),
  );

  void _showWorkbookPdf(Course course) => showPdfDialog(
    context,
    key: const Key('workbookPdfDialog'),
    title: CoursesLocalizations.of(context)!.courses_workbook,
    fileName: 'workbook-${course.title}.pdf',
    pageFormat: PdfPageFormat.a4,
    build: (format) =>
        workbookPdf(CoursesLocalizations.of(context)!, course, format),
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
              child: Text(CoursesLocalizations.of(context)!.courses_delete),
            ),
          if (isEdit) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              key: const Key('previewCourse'),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(CoursesLocalizations.of(context)!.courses_preview),
              onPressed: _previewCourse,
            ),
          ],
          const Spacer(),
          TextButton(
            key: const Key('cancelCourse'),
            onPressed: () => Navigator.pop(context),
            child: Text(CoursesLocalizations.of(context)!.courses_cancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('saveCourse'),
            onPressed: _saveCourse,
            child: Text(
              isEdit
                  ? CoursesLocalizations.of(context)!.courses_update
                  : CoursesLocalizations.of(context)!.courses_create,
            ),
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
        return CoursesLocalizations.of(context)!.courses_beginner;
      case CourseDifficulty.intermediate:
        return CoursesLocalizations.of(context)!.courses_intermediate;
      case CourseDifficulty.advanced:
        return CoursesLocalizations.of(context)!.courses_advanced;
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
            child: Text(CoursesLocalizations.of(context)!.courses_cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<CourseBloc>().add(CourseDelete(widget.course!));
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(CoursesLocalizations.of(context)!.courses_delete),
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
              decoration: InputDecoration(
                labelText: CoursesLocalizations.of(
                  context,
                )!.courses_moduleTitle,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('moduleDescription'),
              controller: descController,
              decoration: InputDecoration(
                labelText: CoursesLocalizations.of(
                  context,
                )!.courses_description,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(CoursesLocalizations.of(context)!.courses_cancel),
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
            child: Text(CoursesLocalizations.of(context)!.courses_add),
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
              decoration: InputDecoration(
                labelText: CoursesLocalizations.of(
                  context,
                )!.courses_lessonTitle,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('lessonContent'),
              controller: contentController,
              decoration: InputDecoration(
                labelText: CoursesLocalizations.of(
                  context,
                )!.courses_contentMarkdown,
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(CoursesLocalizations.of(context)!.courses_cancel),
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
            child: Text(CoursesLocalizations.of(context)!.courses_add),
          ),
        ],
      ),
    );
  }
}
