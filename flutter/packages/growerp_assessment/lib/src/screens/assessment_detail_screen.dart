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
import 'question_management_screen.dart';
import 'assessment_taking_screen.dart';

/// Screen for viewing assessment details with questions and options
class AssessmentDetailScreen extends StatefulWidget {
  final Assessment assessment;

  const AssessmentDetailScreen({
    super.key,
    required this.assessment,
  });

  @override
  State<AssessmentDetailScreen> createState() => _AssessmentDetailScreenState();
}

class _AssessmentDetailScreenState extends State<AssessmentDetailScreen> {
  List<AssessmentQuestion> _questions = [];
  bool _isLoadingQuestions = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
    });

    try {
      // Note: Backend AssessmentQuestion endpoints not available yet
      // Using mock questions for now
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
        pseudoId: 'Q1',
        assessmentId: widget.assessment.assessmentId,
        questionSequence: 1,
        questionText: 'How digitally mature is your organization?',
        questionType: 'MULTIPLE_CHOICE',
        isRequired: true,
        createdDate: DateTime.now(),
      ),
      AssessmentQuestion(
        questionId: '2',
        pseudoId: 'Q2',
        assessmentId: widget.assessment.assessmentId,
        questionSequence: 2,
        questionText: 'What is your current technology adoption level?',
        questionType: 'MULTIPLE_CHOICE',
        isRequired: true,
        createdDate: DateTime.now(),
      ),
      AssessmentQuestion(
        questionId: '3',
        pseudoId: 'Q3',
        assessmentId: widget.assessment.assessmentId,
        questionSequence: 3,
        questionText: 'How would you rate your data analytics capabilities?',
        questionType: 'MULTIPLE_CHOICE',
        isRequired: true,
        createdDate: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assessment.assessmentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editAssessment,
            tooltip: 'Edit Assessment',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_question',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Manage Questions'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'preview',
                child: ListTile(
                  leading: Icon(Icons.preview),
                  title: Text('Preview'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Duplicate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takeAssessment,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Take Assessment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssessmentInfo(),
          const SizedBox(height: 24),
          _buildQuestionsSection(),
        ],
      ),
    );
  }

  Widget _buildAssessmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Colors.green[700],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assessment.assessmentName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.assessment.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.assessment.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.assessment.description?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.assessment.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Created',
                    _formatDate(widget.assessment.createdDate),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Questions',
                    _questions.length.toString(),
                    Icons.quiz,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${_questions.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: _manageQuestions,
              icon: const Icon(Icons.edit),
              label: const Text('Manage Questions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingQuestions)
          const Center(child: LoadingIndicator())
        else if (_questions.isEmpty)
          _buildEmptyQuestionsState()
        else
          ..._questions.map((question) => _buildQuestionCard(question)),
      ],
    );
  }

  Widget _buildEmptyQuestionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.quiz, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Questions Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add questions to make this assessment interactive',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _manageQuestions,
              icon: const Icon(Icons.add),
              label: const Text('Add First Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(AssessmentQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${question.questionSequence}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question.questionType,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          if (question.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleQuestionAction(value, question),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Question options will be loaded from the backend',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      case 'INACTIVE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_question':
        _manageQuestions();
        break;
      case 'preview':
        _previewAssessment();
        break;
      case 'share':
        _shareAssessment();
        break;
      case 'duplicate':
        _duplicateAssessment();
        break;
    }
  }

  void _handleQuestionAction(String action, AssessmentQuestion question) {
    switch (action) {
      case 'edit':
        _editQuestion(question);
        break;
      case 'duplicate':
        _duplicateQuestion(question);
        break;
      case 'delete':
        _deleteQuestion(question);
        break;
    }
  }

  void _editAssessment() {
    HelperFunctions.showMessage(
      context,
      'Edit assessment feature coming soon',
      Colors.orange,
    );
  }

  void _manageQuestions() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => QuestionManagementScreen(
          assessment: widget.assessment,
        ),
      ),
    );

    // Reload questions if changes were made
    if (result == true) {
      _loadQuestions();
    }
  }

  void _previewAssessment() {
    HelperFunctions.showMessage(
      context,
      'Preview assessment feature coming soon',
      Colors.blue,
    );
  }

  void _shareAssessment() {
    HelperFunctions.showMessage(
      context,
      'Share assessment feature coming soon',
      Colors.green,
    );
  }

  void _duplicateAssessment() {
    HelperFunctions.showMessage(
      context,
      'Duplicate assessment feature coming soon',
      Colors.purple,
    );
  }

  void _editQuestion(AssessmentQuestion question) {
    HelperFunctions.showMessage(
      context,
      'Edit question feature coming soon',
      Colors.orange,
    );
  }

  void _duplicateQuestion(AssessmentQuestion question) {
    HelperFunctions.showMessage(
      context,
      'Duplicate question feature coming soon',
      Colors.purple,
    );
  }

  void _deleteQuestion(AssessmentQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
          'Are you sure you want to delete this question?\n\n"${question.questionText}"',
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
                _questions
                    .removeWhere((q) => q.questionId == question.questionId);
              });
              HelperFunctions.showMessage(
                context,
                'Question deleted',
                Colors.green,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _takeAssessment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssessmentTakingScreen(
          assessment: widget.assessment,
        ),
      ),
    );
  }
}
