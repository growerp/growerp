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
import 'dart:convert';

/// Detailed view of an assessment result showing individual answers and scoring
class AssessmentResultDetailScreen extends StatelessWidget {
  final AssessmentResult result;

  const AssessmentResultDetailScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final answers = _parseAnswers(result.answersData);
    final score = result.score;
    final percentage = (score / 100 * 100).round(); // Assuming max score is 100

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Details'),
        backgroundColor: _getScoreColor(percentage),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResultDetails(context),
            tooltip: 'Share Details',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultSummary(score, percentage),
            const SizedBox(height: 24),
            _buildRespondentInfo(),
            const SizedBox(height: 24),
            _buildAnswersSection(answers),
            const SizedBox(height: 24),
            _buildScoreBreakdown(answers),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary(double score, int percentage) {
    final color = _getScoreColor(percentage);
    final grade = _getGrade(percentage);

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
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assessment,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assessment Result',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lead Status: ${result.leadStatus}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                  score.toStringAsFixed(1),
                  color,
                ),
                _buildScoreMetric(
                  'Grade',
                  grade,
                  color,
                ),
                _buildScoreMetric(
                  'Status',
                  result.leadStatus,
                  color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
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
            fontSize: 20,
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

  Widget _buildRespondentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Respondent Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', result.respondentName),
            _buildInfoRow('Email', result.respondentEmail),
            if (result.respondentPhone?.isNotEmpty == true)
              _buildInfoRow('Phone', result.respondentPhone!),
            if (result.respondentCompany?.isNotEmpty == true)
              _buildInfoRow('Company', result.respondentCompany!),
            _buildInfoRow('Completed', _formatDate(result.createdDate)),
            _buildInfoRow('Result ID', result.pseudoId),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersSection(Map<String, String> answers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.quiz, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Assessment Answers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (answers.isEmpty)
              const Text(
                'No detailed answers available',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...answers.entries
                  .map((entry) => _buildAnswerItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerItem(String questionId, String selectedOption) {
    final question = _getQuestionText(questionId);
    final optionText = _getOptionText(questionId, selectedOption);
    final isCorrect = _isAnswerCorrect(questionId, selectedOption);
    final points = _getOptionScore(questionId, selectedOption);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q$questionId',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${points.toStringAsFixed(0)} pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.radio_button_checked,
                size: 16,
                color: isCorrect ? Colors.green[600] : Colors.orange[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    color: isCorrect ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(Map<String, String> answers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Score Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildScoreRow('Total Questions', answers.length.toString()),
            _buildScoreRow('Total Score', result.score.toStringAsFixed(1)),
            _buildScoreRow(
                'Average per Question',
                answers.isNotEmpty
                    ? (result.score / answers.length).toStringAsFixed(1)
                    : '0.0'),
            const Divider(),
            _buildScoreRow(
                'Performance Level', _getPerformanceLevel(result.score)),
            _buildScoreRow('Lead Classification', result.leadStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _exportResults(context),
            icon: const Icon(Icons.download),
            label: const Text('Export Results'),
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
                onPressed: () => _shareResultDetails(context),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Map<String, String> _parseAnswers(String answersData) {
    try {
      if (answersData.isEmpty) return {};
      final decoded = json.decode(answersData) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // If JSON parsing fails, try simple parsing
      return _parseSimpleAnswers(answersData);
    }
  }

  Map<String, String> _parseSimpleAnswers(String answersData) {
    final Map<String, String> answers = {};
    if (answersData.startsWith('{') && answersData.endsWith('}')) {
      final content = answersData.substring(1, answersData.length - 1);
      final pairs = content.split(',');
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].replaceAll('"', '').trim();
          final value = keyValue[1].replaceAll('"', '').trim();
          answers[key] = value;
        }
      }
    }
    return answers;
  }

  String _getQuestionText(String questionId) {
    // Mock question texts - in real app, fetch from assessment data
    final questions = {
      '1': 'How digitally mature is your organization?',
      '2': 'What is your current technology adoption level?',
      '3': 'How would you rate your data analytics capabilities?',
      '4': 'What is your approach to digital transformation?',
      '5': 'How do you handle customer digital interactions?',
    };
    return questions[questionId] ?? 'Question $questionId';
  }

  String _getOptionText(String questionId, String optionId) {
    // Mock option texts - in real app, fetch from assessment data
    final options = {
      '1': 'Just starting digital transformation',
      '2': 'Some digital processes in place',
      '3': 'Advanced digital capabilities',
      '4': 'Fully digital organization',
      '5': 'Basic technology tools',
      '6': 'Moderate technology adoption',
      '7': 'Advanced technology integration',
      '8': 'Cutting-edge technology leader',
      '9': 'Limited data collection',
      '10': 'Basic reporting capabilities',
      '11': 'Advanced analytics and insights',
      '12': 'AI-powered data intelligence',
    };
    return options[optionId] ?? 'Option $optionId';
  }

  bool _isAnswerCorrect(String questionId, String optionId) {
    // Mock scoring - in real app, determine based on scoring rules
    final optionPoints = _getOptionScore(questionId, optionId);
    return optionPoints >= 3.0; // Consider 3+ points as "good" answers
  }

  double _getOptionScore(String questionId, String optionId) {
    // Mock scoring system - in real app, get from assessment configuration
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
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    return 'D';
  }

  String _getPerformanceLevel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareResultDetails(BuildContext context) {
    HelperFunctions.showMessage(
      context,
      'Detailed result sharing functionality coming soon',
      Colors.blue,
    );
  }

  void _exportResults(BuildContext context) {
    HelperFunctions.showMessage(
      context,
      'Result export functionality coming soon',
      Colors.blue,
    );
  }
}
