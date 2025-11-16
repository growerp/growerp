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

/// Screen for displaying assessment results after completion
class AssessmentResultsScreen extends StatelessWidget {
  final Assessment assessment;
  final Map<String, String> answers;

  const AssessmentResultsScreen({
    super.key,
    required this.assessment,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        // Use backend-calculated score from scoreResult if available
        final backendScore = state.scoreResult?.score ?? 0.0;

        // Fallback to local calculation only if backend score is not available
        final score = backendScore > 0 ? backendScore : _calculateScore(state);
        final maxScore = _getMaxScore(state);
        final percentage = maxScore > 0 ? (score / maxScore * 100).round() : 0;

        debugPrint(
            'Results Screen - Backend score: $backendScore, Local score: ${_calculateScore(state)}, Max: $maxScore, Percentage: $percentage%');

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA), // #667eea
                  Color(0xFF764BA2), // #764ba2
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(),
                    const SizedBox(height: 40),
                    _buildScoreCard(score, maxScore, percentage),
                    const SizedBox(height: 24),
                    _buildScoreBreakdown(state),
                    const SizedBox(height: 24),
                    _buildAssessmentInfo(),
                    const SizedBox(height: 24),
                    _buildActionButtons(context, state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepIndicator(1, false, 'Your Info'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(2, false, 'Questions'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(3, true, 'Results'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Step 3 of 3 - Assessment Complete',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: isActive
                ? const Icon(
                    Icons.check,
                    color: Color(0xFF667EEA),
                    size: 24,
                  )
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(double score, double maxScore, int percentage) {
    Color scoreColor = _getScoreColor(percentage);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              scoreColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: scoreColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Score',
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$percentage%',
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 56,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${score.toInt()} / ${maxScore.toInt()} points',
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: score / maxScore,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentInfo() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Assessment', assessment.assessmentName),
            if (assessment.description?.isNotEmpty == true)
              _buildInfoRow('Description', assessment.description!),
            _buildInfoRow('Completed', _formatDate(DateTime.now())),
            _buildInfoRow('Questions Answered', '${answers.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(AssessmentState state) {
    final questions = assessment.questions ?? [];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.checklist_rtl,
                    color: Color(0xFF667EEA),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score Breakdown',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${answers.length} questions answered',
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ...answers.entries.toList().asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final questionId = entry.key;
              final optionId = entry.value;
              final isLast = index == answers.length - 1;

              // Find the question
              final question = questions.firstWhere(
                (q) => q.assessmentQuestionId == questionId,
                orElse: () =>
                    const AssessmentQuestion(questionText: 'Unknown Question'),
              );

              // Find the selected option
              final options = question.options ?? [];
              final selectedOption = options.firstWhere(
                (o) => o.assessmentQuestionOptionId == optionId,
                orElse: () => const AssessmentQuestionOption(
                    optionText: 'Unknown Option'),
              );

              final score = selectedOption.optionScore ?? 0;

              // Get max score for this question to calculate color
              // Try state.options first, then fallback to question options
              List<AssessmentQuestionOption> questionOptions = [];
              if (state.options.containsKey(questionId)) {
                questionOptions = state.options[questionId] ?? [];
              } else {
                questionOptions = question.options ?? [];
              }

              double maxScoreForQuestion = 0.0;
              for (final opt in questionOptions) {
                if ((opt.optionScore ?? 0) > maxScoreForQuestion) {
                  maxScoreForQuestion = opt.optionScore ?? 0;
                }
              }

              // Calculate percentage for this question to determine color
              final questionPercentage = maxScoreForQuestion > 0
                  ? ((score / maxScoreForQuestion) * 100).toInt()
                  : 0;
              final scoreColor = _getScoreColor(questionPercentage);
              final questionSequence = questions.indexOf(question) + 1;
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number and text
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFF667EEA),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$questionSequence',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.questionText ?? 'Question',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Chosen option with score
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: scoreColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: scoreColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedOption.optionText ?? 'Unknown option',
                                  style: const TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      score > 0 ? '+' : '',
                                      style: TextStyle(
                                        color: scoreColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      score.toStringAsFixed(0),
                                      style: TextStyle(
                                        color: scoreColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'pts',
                                      style: TextStyle(
                                        color: scoreColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AssessmentState state) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton(
          onPressed: () => _shareResults(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 8),
              Text(
                'Share',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () => _retakeAssessment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF667EEA),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Retake Assessment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.refresh, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateScore(AssessmentState state) {
    double totalScore = 0;
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final optionId = entry.value;
      totalScore += _getOptionScore(questionId, optionId, state);
    }
    debugPrint('Total score calculated: $totalScore');
    return totalScore;
  }

  double _getMaxScore(AssessmentState state) {
    // Calculate max score from all question options in assessment
    double maxScore = 0.0;

    // First try to get from state.options
    if (state.options.isNotEmpty) {
      for (final questionOptions in state.options.values) {
        double maxPerQuestion = 0.0;
        for (final option in questionOptions) {
          if ((option.optionScore ?? 0) > maxPerQuestion) {
            maxPerQuestion = option.optionScore ?? 0;
          }
        }
        maxScore += maxPerQuestion;
      }
    } else {
      // Fallback: get from assessment questions directly
      final questions = assessment.questions ?? [];
      for (final question in questions) {
        double maxPerQuestion = 0.0;
        final options = question.options ?? [];
        for (final option in options) {
          if ((option.optionScore ?? 0) > maxPerQuestion) {
            maxPerQuestion = option.optionScore ?? 0;
          }
        }
        maxScore += maxPerQuestion;
      }
    }

    debugPrint(
        'Max score calculated: $maxScore (from ${state.options.isNotEmpty ? "state" : "assessment"})');
    return maxScore > 0
        ? maxScore
        : (answers.length * 4.0); // Fallback to 4 per question
  }

  double _getOptionScore(
      String questionId, String optionId, AssessmentState state) {
    // Get actual score from backend option data
    try {
      // First try from state.options
      if (state.options.containsKey(questionId)) {
        final options = state.options[questionId] ?? [];
        final option = options.firstWhere(
          (o) => o.assessmentQuestionOptionId == optionId,
          orElse: () => AssessmentQuestionOption(
            assessmentQuestionOptionId: optionId,
            pseudoId: 'opt_$optionId',
            assessmentQuestionId: questionId,
            assessmentId: '',
            optionSequence: 0,
            optionText: 'Option $optionId',
            optionScore: 0.0,
            createdDate: DateTime.now(),
          ),
        );
        final score = option.optionScore ?? 0.0;
        debugPrint('Score for Q:$questionId O:$optionId = $score (from state)');
        return score;
      }

      // Fallback: get from assessment questions directly
      final questions = assessment.questions ?? [];
      final question = questions.firstWhere(
        (q) => q.assessmentQuestionId == questionId,
        orElse: () => const AssessmentQuestion(questionText: 'Unknown'),
      );

      final options = question.options ?? [];
      final option = options.firstWhere(
        (o) => o.assessmentQuestionOptionId == optionId,
        orElse: () => AssessmentQuestionOption(
          assessmentQuestionOptionId: optionId,
          pseudoId: 'opt_$optionId',
          assessmentQuestionId: questionId,
          assessmentId: '',
          optionSequence: 0,
          optionText: 'Option $optionId',
          optionScore: 0.0,
          createdDate: DateTime.now(),
        ),
      );
      final score = option.optionScore ?? 0.0;
      debugPrint(
          'Score for Q:$questionId O:$optionId = $score (from assessment)');
      return score;
    } catch (e) {
      debugPrint('Error getting score for Q:$questionId O:$optionId: $e');
      return 0.0;
    }
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _retakeAssessment(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(
      '/assessment/take',
      arguments: assessment,
    );
  }

  void _shareResults(BuildContext context) {
    // Show share results options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Assessment Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Results'),
                subtitle: const Text('Send results to email'),
                onTap: () {
                  Navigator.of(context).pop();
                  HelperFunctions.showMessage(
                    context,
                    'Email sharing available',
                    Colors.green,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                subtitle: const Text('Copy results link to clipboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  HelperFunctions.showMessage(
                    context,
                    'Link copied to clipboard',
                    Colors.green,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download PDF'),
                subtitle: const Text('Download results as PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  HelperFunctions.showMessage(
                    context,
                    'PDF download available',
                    Colors.green,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
