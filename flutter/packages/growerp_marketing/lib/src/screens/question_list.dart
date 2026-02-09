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
import 'question_list_styled_data.dart';

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
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late QuestionBloc _questionBloc;
  List<AssessmentQuestion> questions = const <AssessmentQuestion>[];
  bool _isLoading = true;
  String searchString = '';

  @override
  void initState() {
    super.initState();
    _questionBloc = context.read<QuestionBloc>()
      ..add(QuestionLoad(widget.assessmentId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
              .where((q) =>
                  (q.questionText ?? '')
                      .toLowerCase()
                      .contains(searchString.toLowerCase()) ||
                  (q.questionType ?? '')
                      .toLowerCase()
                      .contains(searchString.toLowerCase()))
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
        onRowTap: (index) {
          final question = filtered[index];
          showDialog(
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
          _isLoading = state.status == QuestionStatus.loading;
          questions = state.questions;

          return Column(
            children: [
              ListFilterBar(
                searchHint: 'Search questions...',
                searchController: _searchController,
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
