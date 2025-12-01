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
                    _buildAdviceCard(score, state),
                    const SizedBox(height: 24),
                    _buildScoreBreakdown(state),
                    const SizedBox(height: 24),
                    _buildAssessmentInfo(),
                    const SizedBox(height: 24),
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

  Widget _buildAdviceCard(double score, AssessmentState state) {
    // Find matching threshold
    final thresholds = state.thresholds.isNotEmpty
        ? state.thresholds
        : assessment.thresholds ?? [];

    if (thresholds.isEmpty) return const SizedBox.shrink();

    // Calculate percentage (same as in build method)
    final maxScore = _getMaxScore(state);
    final percentage = maxScore > 0 ? (score / maxScore * 100).round() : 0;

    // Determine if thresholds are percentage-based or raw-score-based
    double maxThresholdScore = 0;
    for (final t in thresholds) {
      if ((t.maxScore ?? 0) > maxThresholdScore) {
        maxThresholdScore = t.maxScore ?? 0;
      }
    }

    // If max threshold > 100, assume raw scores and scale user score to match
    // Otherwise compare percentage directly
    final double scoreToCompare;
    if (maxThresholdScore > 100) {
      scoreToCompare = (percentage / 100) * maxThresholdScore;
    } else {
      scoreToCompare = percentage.toDouble();
    }

    ScoringThreshold? matchingThreshold;
    for (final threshold in thresholds) {
      if ((threshold.minScore ?? 0) <= scoreToCompare &&
          scoreToCompare <= (threshold.maxScore ?? double.infinity)) {
        matchingThreshold = threshold;
        break;
      }
    }

    if (matchingThreshold == null || matchingThreshold.description == null) {
      return const SizedBox.shrink();
    }

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
                    Icons.lightbulb_outline,
                    color: Color(0xFF667EEA),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Our Advice',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              matchingThreshold.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF4A5568),
              ),
            ),
            if (matchingThreshold.leadStatus != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Status: ${matchingThreshold.leadStatus}',
                  style: const TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
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

              // Check if this is a text-type question
              final isTextQuestion = question.questionType == 'Text' ||
                  question.questionType == 'OpenText';

              // For text questions, optionId contains the user's text answer
              // For multiple-choice, optionId is the selected option ID
              String answerText;
              double score = 0;
              Color scoreColor;

              if (isTextQuestion) {
                // Text question: use optionId as the answer text
                answerText =
                    optionId.isNotEmpty ? optionId : 'No answer provided';
                scoreColor = const Color(0xFF667EEA); // Neutral color for text
              } else {
                // Multiple-choice question: find the selected option
                final options = question.options ?? [];
                final selectedOption = options.firstWhere(
                  (o) => o.assessmentQuestionOptionId == optionId,
                  orElse: () => const AssessmentQuestionOption(
                      optionText: 'Unknown Option'),
                );

                answerText = selectedOption.optionText ?? 'Unknown option';
                score = selectedOption.optionScore ?? 0;

                // Get max score for this question to calculate color
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
                scoreColor = _getScoreColor(questionPercentage);
              }

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

                        // Answer display (different for text vs multiple-choice)
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isTextQuestion
                                    ? Icons.comment_outlined
                                    : Icons.check_circle_rounded,
                                color: scoreColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  answerText,
                                  style: const TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              // Only show score badge for multiple-choice questions
                              if (!isTextQuestion)
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
}
