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

/// Simple content widget for displaying leads in a dialog
class AssessmentLeadsScreenContent extends StatefulWidget {
  final String assessmentId;

  const AssessmentLeadsScreenContent({
    super.key,
    required this.assessmentId,
  });

  @override
  State<AssessmentLeadsScreenContent> createState() =>
      _AssessmentLeadsScreenContentState();
}

class _AssessmentLeadsScreenContentState
    extends State<AssessmentLeadsScreenContent> {
  late ScrollController _scrollController;
  int _start = 0;
  static const int _limit = 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Fetch leads on init
    context.read<AssessmentBloc>().add(
          AssessmentFetchLeads(
            assessmentId: widget.assessmentId,
            refresh: true,
          ),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      // User scrolled to bottom, load more
      _start += _limit;
      context.read<AssessmentBloc>().add(
            AssessmentFetchLeads(
              assessmentId: widget.assessmentId,
              start: _start,
              limit: _limit,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<AssessmentBloc, AssessmentState>(
        listener: (context, state) {
          if (state.status == AssessmentStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'Error',
              Colors.red,
            );
          }
        },
        builder: (context, state) {
          if (state.status == AssessmentStatus.loading &&
              state.results.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          if (state.results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No leads have submitted this assessment yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: state.results.length +
                (state.status == AssessmentStatus.loading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.results.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final result = state.results[index];
              return _buildLeadCard(context, result);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, AssessmentResult result) {
    final scoreColor = _getScoreColor(result.score ?? 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          _showResultDetails(context, result);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Score circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withAlpha((0.2 * 255).round()),
                ),
                child: Center(
                  child: Text(
                    '${result.score?.toStringAsFixed(0) ?? '0'}%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.respondentName ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.respondentEmail ?? 'No email',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDetails(BuildContext context, AssessmentResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: "Lead Details - ${result.respondentName ?? 'Unknown'}",
          height: 650,
          width: 500,
          child: _ResultDetailsContent(
            result: result,
            onGetStatusColor: _getStatusColor,
            onGetScoreColor: _getScoreColor,
            onFormatDateTime: _formatDateTime,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOT':
      case 'QUALIFIED':
        return Colors.green;
      case 'WARM':
      case 'INTERESTED':
        return Colors.orange;
      case 'COLD':
      case 'NOT_QUALIFIED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Screen to display leads (assessment respondents) and their scores in a dialog
class AssessmentLeadsScreen extends StatefulWidget {
  final String assessmentId;
  final String assessmentName;

  const AssessmentLeadsScreen({
    super.key,
    required this.assessmentId,
    required this.assessmentName,
  });

  @override
  State<AssessmentLeadsScreen> createState() => _AssessmentLeadsScreenState();
}

class _AssessmentLeadsScreenState extends State<AssessmentLeadsScreen> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: popUp(
        context: context,
        title: "Leads - ${widget.assessmentName}",
        height: 600,
        width: 400,
        child: AssessmentLeadsScreenContent(
          assessmentId: widget.assessmentId,
        ),
      ),
    );
  }
}

/// Widget to show detailed result information with score badge and expandable sections
class _ResultDetailsContent extends StatelessWidget {
  final AssessmentResult result;
  final Color Function(String) onGetStatusColor;
  final Color Function(double) onGetScoreColor;
  final String Function(DateTime?) onFormatDateTime;

  const _ResultDetailsContent({
    required this.result,
    required this.onGetStatusColor,
    required this.onGetScoreColor,
    required this.onFormatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = onGetScoreColor(result.score ?? 0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score badge and basic info
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withAlpha((0.2 * 255).round()),
                ),
                child: Center(
                  child: Text(
                    '${result.score?.toStringAsFixed(0) ?? '0'}%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.respondentEmail ?? 'No email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: onGetStatusColor(result.leadStatus ?? 'Unknown')
                            .withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        result.leadStatus ?? 'Unknown',
                        style: TextStyle(
                          color:
                              onGetStatusColor(result.leadStatus ?? 'Unknown'),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contact Information Section
          _ContactInfoSection(
            result: result,
            onGetStatusColor: onGetStatusColor,
            onFormatDateTime: onFormatDateTime,
          ),
          const SizedBox(height: 16),

          // Individual Answers Section
          if (result.answersData != null && result.answersData!.isNotEmpty)
            _AnswersDropdownSection(
              enrichedAnswers: result.answersData!,
            ),
        ],
      ),
    );
  }
}

/// Contact information section in the details dialog
class _ContactInfoSection extends StatefulWidget {
  final AssessmentResult result;
  final Color Function(String) onGetStatusColor;
  final String Function(DateTime?) onFormatDateTime;

  const _ContactInfoSection({
    required this.result,
    required this.onGetStatusColor,
    required this.onFormatDateTime,
  });

  @override
  State<_ContactInfoSection> createState() => _ContactInfoSectionState();
}

class _ContactInfoSectionState extends State<_ContactInfoSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft:
                      _isExpanded ? Radius.zero : const Radius.circular(8),
                  bottomRight:
                      _isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Contact & Assessment Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget
                              .onGetStatusColor(
                                  widget.result.leadStatus ?? 'Unknown')
                              .withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.result.leadStatus ?? 'Unknown',
                          style: TextStyle(
                            color: widget.onGetStatusColor(
                                widget.result.leadStatus ?? 'Unknown'),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Details
                  if (widget.result.respondentPhone != null)
                    _buildDetailRow('Phone', widget.result.respondentPhone!),
                  if (widget.result.respondentCompany != null)
                    _buildDetailRow(
                        'Company', widget.result.respondentCompany!),
                  _buildDetailRow('Result ID', widget.result.pseudoId ?? 'N/A'),
                  if (widget.result.createdDate != null)
                    _buildDetailRow(
                      'Submitted',
                      widget.onFormatDateTime(widget.result.createdDate),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Answers dropdown section showing individual questions and answers
class _AnswersDropdownSection extends StatefulWidget {
  final List<EnrichedAnswer> enrichedAnswers;

  const _AnswersDropdownSection({
    required this.enrichedAnswers,
  });

  @override
  State<_AnswersDropdownSection> createState() =>
      _AnswersDropdownSectionState();
}

class _AnswersDropdownSectionState extends State<_AnswersDropdownSection> {
  bool _isExpanded = true; // Default expanded

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft:
                      _isExpanded ? Radius.zero : const Radius.circular(8),
                  bottomRight:
                      _isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.quiz, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Individual Answers (${widget.enrichedAnswers.length} questions)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.enrichedAnswers.map((answer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number and text on separate lines for better readability
                        Text(
                          'Question ${answer.questionSequence ?? 0}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          answer.questionText ?? 'Question',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Selected answer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  answer.optionText ?? 'Unknown option',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if ((answer.optionScore ?? 0) > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+${(answer.optionScore ?? 0).toStringAsFixed(0)} pts',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
