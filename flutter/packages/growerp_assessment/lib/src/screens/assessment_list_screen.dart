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
import 'assessment_form_screen.dart';

/// Administrative screen for managing assessments
/// Used by admin interfaces to create, edit, and manage assessments
class AssessmentListScreen extends StatefulWidget {
  const AssessmentListScreen({super.key});

  @override
  State<AssessmentListScreen> createState() => _AssessmentListScreenState();
}

class _AssessmentListScreenState extends State<AssessmentListScreen> {
  final ScrollController _scrollController = ScrollController();
  late AssessmentBloc _assessmentBloc;

  @override
  void initState() {
    super.initState();
    _assessmentBloc = context.read<AssessmentBloc>();
    _assessmentBloc.add(const AssessmentFetch());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        return Scaffold(
          key: const Key('AssessmentListScaffold'),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateAssessmentDialog(context),
            backgroundColor: Colors.green[700],
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(AssessmentState state) {
    if (state.status == AssessmentStatus.loading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.status == AssessmentStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load assessments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(state.message ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _assessmentBloc.add(const AssessmentFetch()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.status == AssessmentStatus.success) {
      if (state.assessments.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          _assessmentBloc.add(const AssessmentFetch());
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: state.assessments.length,
          itemBuilder: (context, index) {
            final assessment = state.assessments[index];
            return _buildAssessmentCard(assessment);
          },
        ),
      );
    }

    // Default state (initial or other)
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Assessments Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first assessment to start lead scoring',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateAssessmentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(Assessment assessment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(
            Icons.assignment,
            color: Colors.green[700],
          ),
        ),
        title: Text(
          assessment.assessmentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assessment.description?.isNotEmpty == true)
              Text(
                assessment.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              'Status: ${assessment.status}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, assessment),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
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
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _viewAssessmentDetail(assessment),
      ),
    );
  }

  void _handleMenuAction(String action, Assessment assessment) {
    switch (action) {
      case 'edit':
        _showEditAssessmentDialog(context, assessment);
        break;
      case 'preview':
        _previewAssessment(assessment);
        break;
      case 'share':
        _shareAssessment(assessment);
        break;
      case 'delete':
        _deleteAssessment(assessment);
        break;
    }
  }

  void _showCreateAssessmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _assessmentBloc,
        child: const CreateAssessmentDialog(),
      ),
    );
  }

  void _showEditAssessmentDialog(BuildContext context, Assessment assessment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _assessmentBloc,
          child: AssessmentFormScreen(assessment: assessment),
        ),
      ),
    );
  }

  void _previewAssessment(Assessment assessment) {
    // TODO: Implement assessment preview
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Preview "${assessment.assessmentName}" feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareAssessment(Assessment assessment) {
    // TODO: Implement assessment sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Share "${assessment.assessmentName}" feature coming soon'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewAssessmentDetail(Assessment assessment) {
    Navigator.pushNamed(
      context,
      '/assessment/detail',
      arguments: assessment,
    );
  }

  void _deleteAssessment(Assessment assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: Text(
          'Are you sure you want to delete "${assessment.assessmentName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _assessmentBloc.add(AssessmentDelete(assessment));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
