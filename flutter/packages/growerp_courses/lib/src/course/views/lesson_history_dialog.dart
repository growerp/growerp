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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';
import 'package:growerp_models/growerp_models.dart';

/// Earlier versions of a lesson; pops true when one was put back.
class LessonHistoryDialog extends StatefulWidget {
  final CourseLesson lesson;

  const LessonHistoryDialog({super.key, required this.lesson});

  @override
  State<LessonHistoryDialog> createState() => _LessonHistoryDialogState();
}

class _LessonHistoryDialogState extends State<LessonHistoryDialog> {
  List<CourseLessonVersion>? _versions;
  CourseLessonVersion? _selected;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await context.read<RestClient>().getCourseLessonHistory(
        lessonId: widget.lesson.lessonId!,
      );
      if (mounted) setState(() => _versions = result.versions);
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) setState(() => _error = message);
    }
  }

  Future<void> _restore(CourseLessonVersion version) async {
    try {
      await context.read<RestClient>().restoreCourseLesson(
        historyId: version.historyId!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  String _reasonLabel(BuildContext context, String? reason) {
    final l10n = CoursesLocalizations.of(context)!;
    switch (reason) {
      case 'AI_LESSONS':
        return l10n.courses_versionByAi;
      case 'RESTORE':
        return l10n.courses_versionRestored;
      default:
        return l10n.courses_versionEdited;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final versions = _versions;
    final selected = _selected;
    return Dialog(
      key: const Key('LessonHistoryDialog'),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: l10n.courses_lessonHistory(widget.lesson.title),
        width: 700,
        height: MediaQuery.of(context).size.height * 0.85,
        child: _error != null
            ? Center(child: Text(_error!))
            : versions == null
            ? const Center(child: CircularProgressIndicator())
            : versions.isEmpty
            ? Center(child: Text(l10n.courses_noEarlierVersions))
            : selected != null
            ? Column(
                children: [
                  ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selected = null),
                    ),
                    title: Text(
                      l10n.courses_versionN(selected.versionNum.toString()),
                    ),
                    trailing: ElevatedButton(
                      key: const Key('restoreVersion'),
                      onPressed: () => _restore(selected),
                      child: Text(l10n.courses_restore),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: MarkdownBody(data: selected.content ?? ''),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: versions.length,
                itemBuilder: (context, index) {
                  final v = versions[index];
                  return ListTile(
                    key: Key('lessonVersion$index'),
                    leading: CircleAvatar(child: Text('${v.versionNum}')),
                    title: Text(
                      '${_reasonLabel(context, v.changeReason)} · '
                      '${v.changedDate?.toLocalizedDateTime(context) ?? ''}',
                    ),
                    subtitle: Text(
                      (v.content ?? '').replaceAll('\n', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() => _selected = v),
                  );
                },
              ),
      ),
    );
  }
}

/// What the outdated-content check found in a lesson. Pops 'apply' to let
/// the AI rewrite the lesson with these changes, 'dismiss' to drop them.
Future<String?> showLessonReviewNotes(
  BuildContext context,
  CourseLesson lesson,
) {
  final l10n = CoursesLocalizations.of(context)!;
  Map notes = {};
  try {
    notes = jsonDecode(lesson.reviewNotes ?? '{}') as Map;
  } catch (_) {}
  final issues = (notes['issues'] as List? ?? []).whereType<Map>().toList();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('lessonReviewNotes'),
      title: Text(l10n.courses_mayBeOutdated(lesson.title)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notes['summary'] != null) Text(notes['summary'].toString()),
              for (final issue in issues)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text('"${issue['text'] ?? ''}"'),
                  subtitle: Text('→ ${issue['suggestion'] ?? ''}'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('dismissReview'),
          onPressed: () => Navigator.pop(dialogContext, 'dismiss'),
          child: Text(l10n.courses_dismiss),
        ),
        ElevatedButton.icon(
          key: const Key('applyReview'),
          icon: const Icon(Icons.auto_awesome),
          onPressed: () => Navigator.pop(dialogContext, 'apply'),
          label: Text(l10n.courses_updateWithAi),
        ),
      ],
    ),
  );
}

/// The issues of the review notes as instructions for the lesson writer
String reviewNotesAsInstructions(CourseLesson lesson) {
  try {
    final notes = jsonDecode(lesson.reviewNotes ?? '{}') as Map;
    return (notes['issues'] as List? ?? [])
        .whereType<Map>()
        .map((i) => '- "${i['text']}" should be: ${i['suggestion']}')
        .join('\n');
  } catch (_) {
    return '';
  }
}
