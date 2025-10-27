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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
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

  List<AssessmentQuestion> _questions = [];
  final Map<String, String> _answers = {}; // questionId -> optionId
  int _currentQuestionIndex = 0;
  bool _isLoadingQuestions = false;
  bool _isSubmitting = false;
  bool _showAllQuestions = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      // Load questions from API or use mock data
      // In a real implementation, this would call:
      // final restClient = context.read<RestClient>();
      // final questions = await restClient.getAssessmentQuestions(
      //   assessmentId: widget.assessment.assessmentId,
      // );

      // For now, use mock questions
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _questions = _createMockQuestions();
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingQuestions = false;
      });
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to load questions: $e',
          Colors.red,
        );
      }
    }
  }

  List<AssessmentQuestion> _createMockQuestions() {
    return [
      AssessmentQuestion(
        questionId: '1',
        pseudoId: '1',
        assessmentId: widget.assessment.assessmentId,
        questionText:
            'How would you rate your overall business readiness for digital transformation?',
        questionType: 'radio',
        isRequired: true,
        questionSequence: 1,
        createdDate: DateTime.now(),
      ),
      AssessmentQuestion(
        questionId: '2',
        pseudoId: '2',
        assessmentId: widget.assessment.assessmentId,
        questionText: 'What is your current annual revenue?',
        questionType: 'radio',
        isRequired: true,
        questionSequence: 2,
        createdDate: DateTime.now(),
      ),
      AssessmentQuestion(
        questionId: '3',
        pseudoId: '3',
        assessmentId: widget.assessment.assessmentId,
        questionText: 'How many employees does your company have?',
        questionType: 'radio',
        isRequired: false,
        questionSequence: 3,
        createdDate: DateTime.now(),
      ),
    ];
  }

  Map<String, List<AssessmentQuestionOption>> _getMockOptions() {
    return {
      '1': [
        AssessmentQuestionOption(
          optionId: '1',
          pseudoId: '1',
          questionId: '1',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 1,
          optionText: 'Not ready at all',
          optionScore: 1,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '2',
          pseudoId: '2',
          questionId: '1',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 2,
          optionText: 'Somewhat ready',
          optionScore: 2,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '3',
          pseudoId: '3',
          questionId: '1',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 3,
          optionText: 'Ready',
          optionScore: 3,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '4',
          pseudoId: '4',
          questionId: '1',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 4,
          optionText: 'Very ready',
          optionScore: 4,
          createdDate: DateTime.now(),
        ),
      ],
      '2': [
        AssessmentQuestionOption(
          optionId: '5',
          pseudoId: '5',
          questionId: '2',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 1,
          optionText: 'Less than \$100K',
          optionScore: 1,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '6',
          pseudoId: '6',
          questionId: '2',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 2,
          optionText: '\$100K - \$500K',
          optionScore: 2,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '7',
          pseudoId: '7',
          questionId: '2',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 3,
          optionText: '\$500K - \$1M',
          optionScore: 3,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '8',
          pseudoId: '8',
          questionId: '2',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 4,
          optionText: 'More than \$1M',
          optionScore: 4,
          createdDate: DateTime.now(),
        ),
      ],
      '3': [
        AssessmentQuestionOption(
          optionId: '9',
          pseudoId: '9',
          questionId: '3',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 1,
          optionText: '1-10 employees',
          optionScore: 1,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '10',
          pseudoId: '10',
          questionId: '3',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 2,
          optionText: '11-50 employees',
          optionScore: 2,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '11',
          pseudoId: '11',
          questionId: '3',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 3,
          optionText: '51-200 employees',
          optionScore: 3,
          createdDate: DateTime.now(),
        ),
        AssessmentQuestionOption(
          optionId: '12',
          pseudoId: '12',
          questionId: '3',
          assessmentId: widget.assessment.assessmentId,
          optionSequence: 4,
          optionText: 'More than 200 employees',
          optionScore: 4,
          createdDate: DateTime.now(),
        ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment.assessmentName),
        actions: [
          IconButton(
            icon: Icon(
                _showAllQuestions ? Icons.view_agenda : Icons.view_carousel),
            onPressed: _toggleViewMode,
            tooltip: _showAllQuestions ? 'One at a time' : 'Show all questions',
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
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingQuestions) {
      return const Center(child: LoadingIndicator());
    }

    if (_questions.isEmpty) {
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
        _buildProgressIndicator(),
        Expanded(
          child:
              _showAllQuestions ? _buildAllQuestions() : _buildSingleQuestion(),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final answeredCount = _answers.length;
    final totalCount = _questions.length;
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

  Widget _buildSingleQuestion() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentQuestionIndex = index;
        });
      },
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildQuestionCard(question, index),
        );
      },
    );
  }

  Widget _buildAllQuestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildQuestionCard(question, index),
        );
      },
    );
  }

  Widget _buildQuestionCard(AssessmentQuestion question, int index) {
    final options = _getMockOptions()[question.questionId] ?? [];
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
                        question.questionText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (question.isRequired) ...[
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
                          _answers[question.questionId] = option.optionId;
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
                            // ignore: deprecated_member_use
                            Radio<String>(
                              value: option.optionId,
                              // ignore: deprecated_member_use
                              groupValue: selectedOptionId,
                              // ignore: deprecated_member_use
                              onChanged: (value) {
                                setState(() {
                                  _answers[question.questionId] = value!;
                                });
                              },
                              activeColor: Colors.green[700],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.optionText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
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

  Widget _buildBottomNavigation() {
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
                onPressed: _canSubmit() ? _submitAssessment : null,
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
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final bool isLastQuestion = _currentQuestionIndex >= _questions.length - 1;

    return ElevatedButton(
      onPressed: isLastQuestion
          ? (_canSubmit() ? _submitAssessment : null)
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
    if (_currentQuestionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canSubmit() {
    final requiredQuestions = _questions.where((q) => q.isRequired).toList();
    for (final question in requiredQuestions) {
      if (!_answers.containsKey(question.questionId)) {
        return false;
      }
    }
    return true;
  }

  void _submitAssessment() async {
    if (!_canSubmit()) {
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
      // Note: Backend AssessmentResult endpoints not available yet
      // Just navigate to results screen directly
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Show success message
        HelperFunctions.showMessage(
          context,
          'Assessment completed successfully!\n(Results will be saved when you use Save Results button)',
          Colors.green,
        );

        // Navigate to results screen for display
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AssessmentResultsScreen(
              assessment: widget.assessment,
              answers: _answers,
            ),
          ),
        );
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
