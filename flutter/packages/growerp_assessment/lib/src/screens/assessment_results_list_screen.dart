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

import 'assessment_result_detail_screen.dart';

/// Administrative screen for viewing assessment results
/// Used by admin interfaces to view and analyze assessment submissions
class AssessmentResultsListScreen extends StatefulWidget {
  const AssessmentResultsListScreen({super.key});

  @override
  State<AssessmentResultsListScreen> createState() =>
      _AssessmentResultsListScreenState();
}

class _AssessmentResultsListScreenState
    extends State<AssessmentResultsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load assessment results from backend via BLoC
    context.read<AssessmentBloc>().add(
          const AssessmentFetchResults(
            assessmentId: '',
            refresh: true,
          ),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AssessmentBloc>().add(
                    const AssessmentFetchResults(
                      assessmentId: '',
                      refresh: true,
                    ),
                  );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        if (state.status == AssessmentStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == AssessmentStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(state.message ?? 'Unknown error'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.read<AssessmentBloc>().add(
                        const AssessmentFetchResults(
                          assessmentId: '',
                          refresh: true,
                        ),
                      ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final results = state.results;
        if (results.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AssessmentBloc>().add(
                  const AssessmentFetchResults(
                    assessmentId: '',
                    refresh: true,
                  ),
                );
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) => _buildResultCard(results[index]),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(AssessmentResult result) {
    return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _viewResultDetail(result),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in,
                        color: Colors.blue[700],
                        size: 24,
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Score: ${result.score.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildScoreBadge(result.score),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.person,
                      result.respondentName,
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      Icons.schedule,
                      _formatDate(result.createdDate),
                    ),
                  ],
                ),
                if (result.respondentEmail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    Icons.email,
                    result.respondentEmail,
                  ),
                ],
              ],
            ),
          ),
        ));
  }

  Widget _buildScoreBadge(double score) {
    Color color;
    String grade;
    if (score >= 80) {
      color = Colors.green;
      grade = 'A';
    } else if (score >= 60) {
      color = Colors.orange;
      grade = 'B';
    } else {
      color = Colors.red;
      grade = 'C';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Text(
        grade,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assessment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Assessment Results Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Results will appear here after users complete and save assessments',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              HelperFunctions.showMessage(
                context,
                'No results to refresh yet',
                Colors.blue,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewResultDetail(AssessmentResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssessmentResultDetailScreen(
          result: result,
        ),
      ),
    );
  }
}
