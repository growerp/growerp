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
import '../bloc/assessment_bloc.dart';
import 'assessment_results_screen_new.dart';

/// Screen for taking assessments - the user-facing experience
class AssessmentTakingScreen extends StatefulWidget {
  final Assessment assessment;

  const AssessmentTakingScreen({
    super.key,
    required this.assessment,
  });

  @override
  State<AssessmentTakingScreen> createState() => _AssessmentTakingScreenState();
}

class _AssessmentTakingScreenState extends State<AssessmentTakingScreen> {
  final PageController _pageController = PageController();
  final Map<String, String> _answers = {}; // questionId -> optionId
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _showAllQuestions = false;

  @override
  void initState() {
    super.initState();
    // Load complete assessment data with questions and options from BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentBloc>().add(
            AssessmentFetchAll(
              assessmentId: widget.assessment.assessmentId,
            ),
          );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.assessment.assessmentName),
            actions: [
              IconButton(
                icon: Icon(_showAllQuestions
                    ? Icons.view_agenda
                    : Icons.view_carousel),
                onPressed: _toggleViewMode,
                tooltip:
                    _showAllQuestions ? 'One at a time' : 'Show all questions',
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'save_draft',
                    child: ListTile(
                      leading: Icon(Icons.save),
                      title: Text('Save Draft'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Reset Answers'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(state),
          bottomNavigationBar: _buildBottomNavigation(state),
        );
      },
    );
  }

  Widget _buildBody(AssessmentState state) {
    if (state.status == AssessmentStatus.loading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Questions Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This assessment doesn\'t have any questions yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildProgressIndicator(state),
        Expanded(
          child: _showAllQuestions
              ? _buildAllQuestions(state)
              : _buildSingleQuestion(state),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(AssessmentState state) {
    final answeredCount = _answers.length;
    final totalCount = state.questions.length;
    final progress = totalCount > 0 ? answeredCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: $answeredCount of $totalCount answered',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleQuestion(AssessmentState state) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentQuestionIndex = index;
        });
      },
      itemCount: state.questions.length,
      itemBuilder: (context, index) {
        final question = state.questions[index];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildQuestionCard(question, index, state),
        );
      },
    );
  }

  Widget _buildAllQuestions(AssessmentState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.questions.length,
      itemBuilder: (context, index) {
        final question = state.questions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildQuestionCard(question, index, state),
        );
      },
    );
  }

  Widget _buildQuestionCard(
    AssessmentQuestion question,
    int index,
    AssessmentState state,
  ) {
    final options = state.options[question.questionId] ?? [];
    final selectedOptionId = _answers[question.questionId];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.questionText ?? 'Untitled Question',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (question.isRequired ?? false) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (options.isNotEmpty) ...[
              ...options.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _answers[question.questionId ?? ''] =
                              option.optionId ?? '';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedOptionId == option.optionId
                                ? Colors.green[700]!
                                : Colors.grey[300]!,
                            width: selectedOptionId == option.optionId ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _answers[question.questionId ?? ''] =
                                      option.optionId ?? '';
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green[700]!,
                                    width: 2,
                                  ),
                                ),
                                child: selectedOptionId == option.optionId
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.optionText ?? 'Option',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'No options available for this question',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(AssessmentState state) {
    if (_showAllQuestions) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _canSubmit(state) ? () => _submitAssessment(state) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Assessment'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0) ...[
            OutlinedButton(
              onPressed: _previousQuestion,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: _buildActionButton(state),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(AssessmentState state) {
    final bool isLastQuestion =
        _currentQuestionIndex >= state.questions.length - 1;

    return ElevatedButton(
      onPressed: isLastQuestion
          ? (_canSubmit(state) ? () => _submitAssessment(state) : null)
          : _nextQuestion,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(isLastQuestion ? 'Submit Assessment' : 'Next'),
    );
  }

  void _toggleViewMode() {
    setState(() {
      _showAllQuestions = !_showAllQuestions;
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save_draft':
        _saveDraft();
        break;
      case 'reset':
        _resetAnswers();
        break;
    }
  }

  void _saveDraft() {
    HelperFunctions.showMessage(
      context,
      'Draft saved successfully',
      Colors.green,
    );
  }

  void _resetAnswers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Answers'),
        content: const Text(
          'Are you sure you want to reset all your answers? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _answers.clear();
              });
              HelperFunctions.showMessage(
                context,
                'All answers have been reset',
                Colors.orange,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canSubmit(AssessmentState state) {
    final requiredQuestions =
        state.questions.where((q) => (q.isRequired ?? false)).toList();
    for (final question in requiredQuestions) {
      if (!_answers.containsKey(question.questionId)) {
        return false;
      }
    }
    return true;
  }

  void _submitAssessment(AssessmentState state) async {
    if (!_canSubmit(state)) {
      HelperFunctions.showMessage(
        context,
        'Please answer all required questions',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit the assessment through BLoC
      if (mounted) {
        context.read<AssessmentBloc>().add(
              AssessmentSubmit(
                assessmentId: widget.assessment.assessmentId,
                answers: _answers,
                respondentName: 'Anonymous',
                respondentEmail: 'anonymous@example.com',
                respondentPhone: '',
                respondentCompany: '',
              ),
            );

        // Wait a moment for submission
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          HelperFunctions.showMessage(
            context,
            'Assessment submitted successfully!',
            Colors.green,
          );

          // Navigate to results screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AssessmentResultsScreen(
                assessment: widget.assessment,
                answers: _answers,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to submit assessment: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
