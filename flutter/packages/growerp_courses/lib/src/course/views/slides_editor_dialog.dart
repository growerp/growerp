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

import '../../documents/course_pdfs.dart';
import '../bloc/course_bloc.dart';

/// The slides of one module: edit, add, delete and preview as pdf. Every
/// change saves the whole deck of the module.
class SlidesEditorDialog extends StatelessWidget {
  final String moduleId;

  const SlidesEditorDialog({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final course = context.select<CourseBloc, Course?>(
      (bloc) => bloc.state.selectedCourse,
    );
    final module = course?.modules
        ?.where((m) => m.moduleId == moduleId)
        .firstOrNull;
    final slides = module?.slides ?? [];
    return Dialog(
      key: const Key('SlidesEditorDialog'),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: CoursesLocalizations.of(
          context,
        )!.courses_slidesOf(module?.title ?? ''),
        width: 600,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: slides.isEmpty
                  ? Center(
                      child: Text(
                        CoursesLocalizations.of(context)!.courses_noSlidesYet,
                      ),
                    )
                  : ListView.builder(
                      itemCount: slides.length,
                      itemBuilder: (context, index) {
                        final slide = slides[index];
                        return ListTile(
                          key: Key('slide$index'),
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(slide.title),
                          subtitle: Text(
                            slide.bullets.join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _edit(context, slides, index),
                          trailing: IconButton(
                            key: Key('deleteSlide$index'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _save(context, [...slides]..removeAt(index)),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton.icon(
                    key: const Key('addSlide'),
                    icon: const Icon(Icons.add),
                    label: Text(
                      CoursesLocalizations.of(context)!.courses_addSlide,
                    ),
                    onPressed: () => _edit(context, slides, null),
                  ),
                  if (slides.isNotEmpty && course != null)
                    TextButton.icon(
                      key: const Key('previewSlides'),
                      icon: const Icon(Icons.slideshow),
                      label: Text(
                        CoursesLocalizations.of(context)!.courses_preview,
                      ),
                      onPressed: () => showPdfDialog(
                        context,
                        key: const Key('slidesPdfDialog'),
                        title: CoursesLocalizations.of(context)!.courses_slides,
                        fileName: 'slides-${module!.title}.pdf',
                        pageFormat: slidePageFormat,
                        build: (format) => slidesPdf(
                          CoursesLocalizations.of(context)!,
                          course,
                          [module],
                          format,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    key: const Key('closeSlides'),
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

  void _save(BuildContext context, List<CourseSlide> slides) =>
      context.read<CourseBloc>().add(CourseModuleSlidesSave(moduleId, slides));

  /// [index] null adds a slide at the end
  Future<void> _edit(
    BuildContext context,
    List<CourseSlide> slides,
    int? index,
  ) async {
    final saved = await showDialog<CourseSlide>(
      context: context,
      builder: (_) => _SlideDialog(slide: index == null ? null : slides[index]),
    );
    if (saved == null || !context.mounted) return;
    final updated = [...slides];
    index == null ? updated.add(saved) : updated[index] = saved;
    _save(context, updated);
  }
}

class _SlideDialog extends StatefulWidget {
  final CourseSlide? slide;
  const _SlideDialog({this.slide});

  @override
  State<_SlideDialog> createState() => _SlideDialogState();
}

class _SlideDialogState extends State<_SlideDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _bullets;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.slide?.title ?? '');
    _bullets = TextEditingController(
      text: widget.slide?.bullets.join('\n') ?? '',
    );
    _notes = TextEditingController(text: widget.slide?.notes ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _bullets.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.slide == null
            ? CoursesLocalizations.of(context)!.courses_addSlide
            : CoursesLocalizations.of(context)!.courses_editSlide,
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
                  key: const Key('slideTitle'),
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: CoursesLocalizations.of(
                      context,
                    )!.courses_titleLabel,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? CoursesLocalizations.of(context)!.courses_enterTitle
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('slideBullets'),
                  controller: _bullets,
                  decoration: InputDecoration(
                    labelText: CoursesLocalizations.of(
                      context,
                    )!.courses_bulletsOnePerLine,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('slideNotes'),
                  controller: _notes,
                  decoration: InputDecoration(
                    labelText: CoursesLocalizations.of(
                      context,
                    )!.courses_speakerNotes,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
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
          key: const Key('saveSlide'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              CourseSlide(
                title: _title.text.trim(),
                bullets: _bullets.text
                    .split('\n')
                    .map((b) => b.trim())
                    .where((b) => b.isNotEmpty)
                    .toList(),
                notes: _notes.text.trim(),
              ),
            );
          },
          child: Text(CoursesLocalizations.of(context)!.courses_save),
        ),
      ],
    );
  }
}
