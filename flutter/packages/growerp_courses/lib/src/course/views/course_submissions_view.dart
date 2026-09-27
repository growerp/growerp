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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';
import 'package:growerp_models/growerp_models.dart';

/// The learner work of a course for its authors: search, "needs review"
/// filter, tap a row to review it.
class CourseSubmissionsView extends StatefulWidget {
  final String courseId;

  const CourseSubmissionsView({super.key, required this.courseId});

  @override
  State<CourseSubmissionsView> createState() => _CourseSubmissionsViewState();
}

class _CourseSubmissionsViewState extends State<CourseSubmissionsView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<CourseSubmission> _submissions = [];
  bool _needsReview = true;
  bool _loading = true;
  String _search = '';

  /// a later search wins over an earlier one still on its way
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    try {
      final result = await context.read<RestClient>().getCourseSubmissions(
        courseId: widget.courseId,
        needsReview: _needsReview,
        searchString: _search.isEmpty ? null : _search,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _submissions = result.submissions;
        _loading = false;
      });
    } catch (e) {
      final message = await getDioError(e);
      if (!mounted || requestId != _requestId) return;
      setState(() => _loading = false);
      HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final isPhone = isAPhone(context);
    final columns = isPhone
        ? [
            StyledColumn(header: l10n.courses_learner, flex: 4),
            StyledColumn(header: l10n.courses_score, flex: 2),
          ]
        : [
            StyledColumn(header: l10n.courses_learner, flex: 3),
            StyledColumn(header: l10n.courses_exercise, flex: 3),
            StyledColumn(header: l10n.courses_submitted, flex: 2),
            StyledColumn(header: l10n.courses_score, flex: 1),
            StyledColumn(header: l10n.courses_status, flex: 2),
          ];
    final rows = [
      for (final (index, s) in _submissions.indexed)
        isPhone
            ? [
                Column(
                  key: Key('submission$index'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.learnerName ?? s.username ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.exerciseTitle ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                _scoreText(s),
              ]
            : [
                Text(
                  s.learnerName ?? s.username ?? '',
                  key: Key('submission$index'),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(s.exerciseTitle ?? '', overflow: TextOverflow.ellipsis),
                Text(s.submittedDate?.toLocalizedDateOnly(context) ?? ''),
                _scoreText(s),
                Text(_statusLabel(context, s)),
              ],
    ];
    return Column(
      children: [
        ListFilterBar(
          searchHint: l10n.courses_searchSubmissions,
          searchController: _searchController,
          onSearchChanged: (value) {
            _search = value.trim();
            _load();
          },
          filters: [
            FilterChip(
              key: const Key('needsReview'),
              label: Text(l10n.courses_needsReview),
              selected: _needsReview,
              onSelected: (value) {
                _needsReview = value;
                _load();
              },
            ),
          ],
        ),
        Expanded(
          child: !_loading && _submissions.isEmpty
              ? Center(child: Text(l10n.courses_noSubmissions))
              : StyledDataTable(
                  columns: columns,
                  rows: rows,
                  isLoading: _loading && _submissions.isEmpty,
                  scrollController: _scrollController,
                  rowHeight: isPhone ? 64 : 48,
                  onRowTap: (index) async {
                    final reviewed = await showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          SubmissionReviewDialog(submission: _submissions[index]),
                    );
                    if (reviewed == true) _load();
                  },
                ),
        ),
      ],
    );
  }

  Widget _scoreText(CourseSubmission s) => Text(
    s.score == null ? '-' : '${s.score}%',
    style: TextStyle(
      color: s.score == null
          ? null
          : s.passed
          ? Colors.green
          : Colors.orange,
      fontWeight: FontWeight.w600,
    ),
  );

  String _statusLabel(BuildContext context, CourseSubmission s) {
    final l10n = CoursesLocalizations.of(context)!;
    switch (s.status) {
      case 'REVIEWED':
        return l10n.courses_statusReviewed;
      case 'AI_GRADED':
        return l10n.courses_statusAiGraded;
      default:
        return l10n.courses_statusSubmitted;
    }
  }
}

/// Instructor review of one submission: the answer, the AI feedback, and the
/// instructor score and feedback that count over the AI.
class SubmissionReviewDialog extends StatefulWidget {
  final CourseSubmission submission;

  const SubmissionReviewDialog({super.key, required this.submission});

  @override
  State<SubmissionReviewDialog> createState() => _SubmissionReviewDialogState();
}

class _SubmissionReviewDialogState extends State<SubmissionReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _score;
  late final TextEditingController _feedback;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.submission;
    _score = TextEditingController(
      text: (s.instructorScore ?? s.aiScore)?.toString() ?? '',
    );
    _feedback = TextEditingController(text: s.instructorFeedback ?? '');
  }

  @override
  void dispose() {
    _score.dispose();
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<RestClient>().reviewCourseSubmission(
        submissionId: widget.submission.submissionId!,
        instructorScore: int.parse(_score.text.trim()),
        instructorFeedback: _feedback.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final message = await getDioError(e);
      if (!mounted) return;
      setState(() => _saving = false);
      HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final s = widget.submission;
    return Dialog(
      key: const Key('SubmissionReviewDialog'),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: l10n.courses_reviewSubmission,
        width: 600,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${s.learnerName ?? s.username ?? ''} · ${s.exerciseTitle ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.courses_answer,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(s.answer ?? ''),
              ),
              if (s.aiScore != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${l10n.courses_aiFeedback}: ${s.aiScore}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (s.aiFeedback != null) Text(s.aiFeedback!),
                ...s.improvements.map((i) => Text('• $i')),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('instructorScore'),
                controller: _score,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.courses_scoreLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final score = int.tryParse(v?.trim() ?? '');
                  return score == null || score < 0 || score > 100
                      ? l10n.courses_scoreRange
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('instructorFeedbackField'),
                controller: _feedback,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l10n.courses_instructorFeedback,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.courses_cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const Key('saveReview'),
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.courses_save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
