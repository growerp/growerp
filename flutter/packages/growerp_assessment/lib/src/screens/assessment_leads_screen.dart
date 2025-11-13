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
    final scoreColor = _getScoreColor(result.score);

    return GestureDetector(
      onTap: () {
        _showResultDetails(context, result);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withAlpha((0.2 * 255).round()),
                    ),
                    child: Center(
                      child: Text(
                        '${result.score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                          result.respondentName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.respondentEmail,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(result.leadStatus)
                          .withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.leadStatus,
                      style: TextStyle(
                        color: _getStatusColor(result.leadStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (result.respondentCompany != null)
                    Expanded(
                      child: Text(
                        result.respondentCompany!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (result.createdDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(result.createdDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDetails(BuildContext context, AssessmentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Result Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('Name', result.respondentName),
                      _detailRow('Email', result.respondentEmail),
                      if (result.respondentPhone != null)
                        _detailRow('Phone', result.respondentPhone!),
                      if (result.respondentCompany != null)
                        _detailRow('Company', result.respondentCompany!),
                      _detailRow(
                          'Score', '${result.score.toStringAsFixed(1)}%'),
                      _detailRow('Status', result.leadStatus),
                      _detailRow('Result ID', result.pseudoId),
                      if (result.createdDate != null)
                        _detailRow(
                            'Submitted', _formatDateTime(result.createdDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
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
