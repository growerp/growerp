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
import 'package:growerp_models/growerp_models.dart';

import '../bloc/question_bloc.dart';
import '../bloc/question_event.dart';
import '../bloc/question_state.dart';
import 'question_detail_screen.dart';
import 'question_list_styled_data.dart';

class QuestionListScreen extends StatefulWidget {
  final String assessmentId;

  const QuestionListScreen({super.key, required this.assessmentId});

  @override
  QuestionListScreenState createState() => QuestionListScreenState();
}

class QuestionListScreenState extends State<QuestionListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late QuestionBloc _questionBloc;
  List<AssessmentQuestion> questions = const <AssessmentQuestion>[];
  bool _isLoading = true;
  String searchString = '';

  @override
  void initState() {
    super.initState();
    _questionBloc = context.read<QuestionBloc>()
      ..add(QuestionLoad(widget.assessmentId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);

    Widget tableView() {
      // Filter questions by search string
      final filtered = searchString.isEmpty
          ? questions
          : questions
                .where(
                  (q) =>
                      (q.questionText ?? '').toLowerCase().contains(
                        searchString.toLowerCase(),
                      ) ||
                      (q.questionType ?? '').toLowerCase().contains(
                        searchString.toLowerCase(),
                      ),
                )
                .toList();

      final rows = filtered.map((question) {
        final index = filtered.indexOf(question);
        return getQuestionListRow(
          context: context,
          question: question,
          index: index,
          bloc: _questionBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getQuestionListColumns(context),
        rows: rows,
        isLoading: _isLoading && questions.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) async {
          final question = filtered[index];
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
          if (mounted) _searchFocusNode.requestFocus();
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<QuestionBloc, QuestionState>(
        listener: (context, state) {
          if (state.status == QuestionStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'Error loading questions',
              Colors.red,
            );
            _searchFocusNode.requestFocus();
          }
          if (state.status == QuestionStatus.success &&
              (state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(context, state.message!, Colors.green);
            _searchFocusNode.requestFocus();
          }
        },
        builder: (context, state) {
          _isLoading = state.status == QuestionStatus.loading;
          questions = state.questions;

          return Column(
            children: [
              ListFilterBar(
                searchHint: 'Search questions...',
                searchController: _searchController,
                focusNode: _searchFocusNode,
                onSearchChanged: (value) {
                  setState(() {
                    searchString = value;
                  });
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    tableView(),
                    Positioned(
                      right: isPhone ? 20 : 50,
                      bottom: 50,
                      child: FloatingActionButton(
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
                          if (mounted) _searchFocusNode.requestFocus();
                        },
                        tooltip: 'Add Question',
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
