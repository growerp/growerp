/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/question_bloc.dart';
import '../bloc/question_event.dart';
import '../bloc/question_state.dart';
import 'question_detail_screen.dart';

class QuestionListScreen extends StatefulWidget {
  final String assessmentId;

  const QuestionListScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  QuestionListScreenState createState() => QuestionListScreenState();
}

class QuestionListScreenState extends State<QuestionListScreen> {
  late QuestionBloc _questionBloc;

  @override
  void initState() {
    super.initState();
    _questionBloc = context.read<QuestionBloc>()
      ..add(QuestionLoad(widget.assessmentId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        key: const Key('addQuestion'),
        onPressed: () async {
          await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return BlocProvider.value(
                value: _questionBloc,
                child: QuestionDetailScreen(
                  assessmentId: widget.assessmentId,
                  question: const AssessmentQuestion(),
                ),
              );
            },
          );
        },
        tooltip: 'Add Question',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BlocConsumer<QuestionBloc, QuestionState>(
        listener: (context, state) {
          if (state.status == QuestionStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'Error loading questions',
              Colors.red,
            );
          }
          if (state.status == QuestionStatus.success &&
              (state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        },
        builder: (context, state) {
          if (state.status == QuestionStatus.loading) {
            return const LoadingIndicator();
          }

          if (state.questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a question',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            onReorder: (oldIndex, newIndex) {
              // Handle reordering
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              // TODO: Implement question reordering
            },
            itemCount: state.questions.length,
            itemBuilder: (context, index) {
              final question = state.questions[index];
              return Card(
                key: Key('question${question.assessmentQuestionId}'),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${question.questionSequence ?? index + 1}'),
                  ),
                  title: Text(question.questionText ?? 'Untitled Question'),
                  subtitle: Text(
                    '${question.options?.length ?? 0} options',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Question'),
                                content: const Text(
                                  'Are you sure you want to delete this question?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true) {
                            _questionBloc.add(
                              QuestionDelete(question.assessmentQuestionId ?? ''),
                            );
                          }
                        },
                      ),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                  onTap: () async {
                    await showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return BlocProvider.value(
                          value: _questionBloc,
                          child: QuestionDetailScreen(
                            assessmentId: widget.assessmentId,
                            question: question,
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
