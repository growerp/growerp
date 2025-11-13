import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/assessment_bloc.dart';

/// Step 3: Assessment Results Screen
/// Displays assessment results with score and status
class AssessmentResultsScreen extends StatefulWidget {
  final String assessmentId;
  final String respondentName;
  final VoidCallback onComplete;

  const AssessmentResultsScreen({
    Key? key,
    required this.assessmentId,
    required this.respondentName,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<AssessmentResultsScreen> createState() =>
      _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen> {
  AssessmentResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _waitForResult();
  }

  void _waitForResult() {
    // Wait for the AssessmentSubmitted state from BLoC
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        if (state.status == AssessmentStatus.success &&
            state.results.isNotEmpty) {
          // Get the most recent result (first in the list)
          setState(() {
            _result = state.results.first;
            _isLoading = false;
          });
        } else if (state.status == AssessmentStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assessment - Step 3: Results'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _result != null
                ? _buildResultsView(context)
                : _buildLoadingState(context),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Processing your assessment...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildResultsView(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final result = _result!;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            SizedBox(height: isMobile ? 24 : 40),

            // Score card
            _buildScoreCard(context, result),
            SizedBox(height: isMobile ? 24 : 32),

            // Status card
            _buildStatusCard(context, result),
            SizedBox(height: isMobile ? 24 : 32),

            // Summary
            _buildSummaryCard(context, result),
            SizedBox(height: isMobile ? 24 : 32),

            // Answers (if available)
            if (result.answersData != null) ...[
              _buildAnswersCard(context, result),
              SizedBox(height: isMobile ? 24 : 32),
            ],

            // Actions
            _buildActionButtons(context),
          ],
        ),
      ),
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
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(2, false, 'Questions'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(3, true, 'Results'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Step 3 of 3 - Assessment Complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
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
            color: isActive ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? Colors.blue : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, AssessmentResult result) {
    final score = result.score ?? 0;
    final scoreColor = _getScoreColor(score);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              scoreColor.withAlpha((0.2 * 255).round()),
              scoreColor.withAlpha((0.05 * 255).round())
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Your Score',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${score.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AssessmentResult result) {
    final status = result.leadStatus ?? 'Unknown';
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withAlpha((0.2 * 255).round()),
              ),
              child: Center(
                child: Icon(
                  _getStatusIcon(status),
                  color: statusColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lead Status',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: statusColor,
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

  Widget _buildSummaryCard(BuildContext context, AssessmentResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Respondent', result.respondentName ?? 'Unknown'),
            const SizedBox(height: 12),
            _buildSummaryRow('Email', result.respondentEmail ?? 'No email'),
            const SizedBox(height: 12),
            if (result.respondentPhone != null) ...[
              _buildSummaryRow('Phone', result.respondentPhone!),
              const SizedBox(height: 12),
            ],
            if (result.respondentCompany != null) ...[
              _buildSummaryRow('Company', result.respondentCompany!),
              const SizedBox(height: 12),
            ],
            _buildSummaryRow(
              'Completed',
              _formatDateTime(result.createdDate),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Result ID', result.pseudoId ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersCard(BuildContext context, AssessmentResult result) {
    final answersData = result.answersData;
    if (answersData == null || answersData.isEmpty) {
      return const SizedBox.shrink();
    }

    return _AnswersExpansionCard(
      enrichedAnswers: answersData,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // Implement export/share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export feature coming soon')),
            );
          },
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
        ElevatedButton.icon(
          onPressed: widget.onComplete,
          icon: const Icon(Icons.check_circle),
          label: const Text('Complete'),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'QUALIFIED':
      case 'HOT':
        return Colors.green;
      case 'INTERESTED':
      case 'WARM':
        return Colors.orange;
      case 'NOT_QUALIFIED':
      case 'COLD':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'QUALIFIED':
      case 'HOT':
        return Icons.thumb_up;
      case 'INTERESTED':
      case 'WARM':
        return Icons.info;
      case 'NOT_QUALIFIED':
      case 'COLD':
        return Icons.thumb_down;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Expansion card widget to show individual question answers
class _AnswersExpansionCard extends StatefulWidget {
  final List<EnrichedAnswer> enrichedAnswers;

  const _AnswersExpansionCard({
    required this.enrichedAnswers,
  });

  @override
  State<_AnswersExpansionCard> createState() => _AnswersExpansionCardState();
}

class _AnswersExpansionCardState extends State<_AnswersExpansionCard> {
  bool _isExpanded = true; // Default to expanded on results screen

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isExpanded ? Colors.blue.shade50 : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft:
                      _isExpanded ? Radius.zero : const Radius.circular(12),
                  bottomRight:
                      _isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Answers (${widget.enrichedAnswers.length} questions)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.enrichedAnswers.map((answer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${answer.questionSequence ?? 0}',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    answer.questionText ?? 'Question',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            answer.optionText ??
                                                'Unknown option',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.green.shade900,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                        if ((answer.optionScore ?? 0) > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              '+${(answer.optionScore ?? 0).toStringAsFixed(0)} pts',
                                              style: TextStyle(
                                                color: Colors.blue.shade900,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
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
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
