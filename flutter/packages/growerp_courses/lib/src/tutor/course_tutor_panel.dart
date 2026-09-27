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

/// Open the AI tutor of a course. [lessonId] grounds it on that lesson,
/// [extraContext] on an exercise or the missed quiz questions; [hints] starts
/// in hints-only mode (no solutions).
Future<void> showCourseTutor(
  BuildContext context, {
  required String courseId,
  String? lessonId,
  String? title,
  String? extraContext,
  String? firstMessage,
  bool hints = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      key: const Key('courseTutorDialog'),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: dialogContext,
        title: title ?? CoursesLocalizations.of(context)!.courses_aiTutor,
        width: 600,
        height: MediaQuery.of(dialogContext).size.height * 0.8,
        child: CourseTutorPanel(
          courseId: courseId,
          lessonId: lessonId,
          extraContext: extraContext,
          firstMessage: firstMessage,
          hints: hints,
        ),
      ),
    ),
  );
}

class CourseTutorPanel extends StatefulWidget {
  final String courseId;
  final String? lessonId;
  final String? extraContext;
  final String? firstMessage;
  final bool hints;

  const CourseTutorPanel({
    super.key,
    required this.courseId,
    this.lessonId,
    this.extraContext,
    this.firstMessage,
    this.hints = false,
  });

  @override
  State<CourseTutorPanel> createState() => _CourseTutorPanelState();
}

class _CourseTutorPanelState extends State<CourseTutorPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<({String role, String text})> _turns = [];
  late bool _hints = widget.hints;
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    if (widget.firstMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _send(widget.firstMessage!),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String message) async {
    if (message.trim().isEmpty || _waiting) return;
    final history = _turns
        .map((t) => {'role': t.role, 'text': t.text})
        .toList();
    setState(() {
      _turns.add((role: 'learner', text: message.trim()));
      _waiting = true;
    });
    _controller.clear();
    _scrollDown();
    String answer;
    try {
      var result = await context.read<RestClient>().courseTutor(
        data: {
          'courseId': widget.courseId,
          if (widget.lessonId != null) 'lessonId': widget.lessonId,
          if (widget.extraContext != null)
            'extraContext': widget.extraContext,
          'message': message.trim(),
          'mode': _hints ? 'HINTS' : 'EXPLAIN',
          'history': history,
        },
      );
      if (result is String) result = jsonDecode(result);
      answer = (result['answer'] ?? '').toString();
    } catch (e) {
      answer = '⚠️ ${await getDioError(e)}';
    }
    if (!mounted) return;
    setState(() {
      _turns.add((role: 'tutor', text: answer));
      _waiting = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CoursesLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        SwitchListTile(
          key: const Key('tutorHints'),
          dense: true,
          title: Text(l10n.courses_tutorHintsOnly),
          subtitle: Text(l10n.courses_tutorHintsOnlyHelp),
          value: _hints,
          onChanged: (value) => setState(() => _hints = value),
        ),
        const Divider(height: 1),
        Expanded(
          child: _turns.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.courses_tutorWelcome,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  key: const Key('tutorMessages'),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _turns.length + (_waiting ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _turns.length) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final turn = _turns[index];
                    final isLearner = turn.role == 'learner';
                    return Align(
                      alignment: isLearner
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        key: Key('tutorMessage$index'),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 480),
                        decoration: BoxDecoration(
                          color: isLearner
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isLearner
                            ? Text(turn.text)
                            : MarkdownBody(data: turn.text, selectable: true),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('tutorInput'),
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: l10n.courses_tutorAskHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('tutorSend'),
                icon: const Icon(Icons.send),
                onPressed: _waiting ? null : () => _send(_controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
