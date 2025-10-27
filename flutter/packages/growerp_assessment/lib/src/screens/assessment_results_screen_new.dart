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
    final score = _calculateScore();
    final maxScore = _getMaxScore();
    final percentage = maxScore > 0 ? (score / maxScore * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context),
            tooltip: 'Share Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(score, maxScore, percentage),
            const SizedBox(height: 24),
            _buildAssessmentInfo(),
            const SizedBox(height: 24),
            _buildScoreBreakdown(),
            const SizedBox(height: 24),
            _buildRecommendations(percentage),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(double score, double maxScore, int percentage) {
    Color scoreColor = _getScoreColor(percentage);

    return Card(
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scoreColor.withAlpha((0.1 * 255).round()),
              scoreColor.withAlpha((0.05 * 255).round()),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  size: 32,
                  color: scoreColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assessment.assessmentName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreMetric(
                  'Score',
                  '${score.toInt()}/${maxScore.toInt()}',
                  scoreColor,
                ),
                _buildScoreMetric(
                  'Percentage',
                  '$percentage%',
                  scoreColor,
                ),
                _buildScoreMetric(
                  'Grade',
                  _getGrade(percentage),
                  scoreColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...answers.entries.map((entry) {
              final questionId = entry.key;
              final optionId = entry.value;
              final score = _getOptionScore(questionId, optionId);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          questionId,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Question $questionId'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${score.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(int percentage) {
    final recommendations = _getRecommendations(percentage);
    final color = _getScoreColor(percentage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: color),
                const SizedBox(width: 8),
                const Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _retakeAssessment(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _saveResults(context),
                icon: const Icon(Icons.save),
                label: const Text('Save Results'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareResults(context),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).popUntil(
              ModalRoute.withName('/assessment'),
            ),
            child: const Text('Back to Assessments'),
          ),
        ),
      ],
    );
  }

  double _calculateScore() {
    double totalScore = 0;
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final optionId = entry.value;
      totalScore += _getOptionScore(questionId, optionId);
    }
    return totalScore;
  }

  double _getMaxScore() {
    // Mock calculation - in real implementation, get from API
    return answers.length * 4.0; // Assuming max score per question is 4
  }

  double _getOptionScore(String questionId, String optionId) {
    // Mock scoring - in real implementation, get from API
    switch (optionId) {
      case '1':
      case '5':
      case '9':
        return 1.0;
      case '2':
      case '6':
      case '10':
        return 2.0;
      case '3':
      case '7':
      case '11':
        return 3.0;
      case '4':
      case '8':
      case '12':
        return 4.0;
      default:
        return 0.0;
    }
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getGrade(int percentage) {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  List<String> _getRecommendations(int percentage) {
    if (percentage >= 80) {
      return [
        'Excellent performance! You\'re well-prepared for digital transformation.',
        'Consider sharing your best practices with other organizations.',
        'Focus on maintaining your current momentum and continuous improvement.',
      ];
    } else if (percentage >= 60) {
      return [
        'Good foundation, but there\'s room for improvement.',
        'Focus on areas where you scored lower to strengthen your readiness.',
        'Consider investing in training and technology upgrades.',
      ];
    } else {
      return [
        'Significant improvements needed for digital transformation readiness.',
        'Start with fundamental digital literacy and infrastructure upgrades.',
        'Consider consulting with digital transformation experts.',
        'Develop a comprehensive digital strategy and roadmap.',
      ];
    }
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

  void _saveResults(BuildContext context) {
    try {
      // Submit assessment results to backend via BLoC
      final authState = context.read<AuthBloc>().state;
      final userEmail =
          authState.authenticate?.user?.email ?? 'anonymous@example.com';
      final userName = authState.authenticate?.user?.firstName != null
          ? '${authState.authenticate!.user!.firstName} ${authState.authenticate!.user!.lastName ?? ''}'
              .trim()
          : 'Anonymous User';

      final answerMap = <String, dynamic>{};
      for (final entry in answers.entries) {
        answerMap[entry.key] = entry.value;
      }

      context.read<AssessmentBloc>().add(
            AssessmentSubmit(
              assessmentId: assessment.assessmentId,
              answers: answerMap,
              respondentName: userName,
              respondentEmail: userEmail,
              respondentPhone: authState.authenticate?.user?.telephoneNr,
              respondentCompany: authState.authenticate?.company?.name,
            ),
          );

      // Show success message
      HelperFunctions.showMessage(
        context,
        'Assessment results submitted successfully!\nScore: ${_calculateScore().toStringAsFixed(1)}',
        Colors.green,
      );
    } catch (e) {
      HelperFunctions.showMessage(
        context,
        'Failed to save results: $e',
        Colors.red,
      );
    }
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
