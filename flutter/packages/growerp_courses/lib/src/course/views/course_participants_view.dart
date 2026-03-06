/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_bloc.dart';

/// Admin view showing all enrolled students and their progress for a course.
class CourseParticipantsView extends StatefulWidget {
  final String courseId;

  const CourseParticipantsView({super.key, required this.courseId});

  @override
  State<CourseParticipantsView> createState() => _CourseParticipantsViewState();
}

class _CourseParticipantsViewState extends State<CourseParticipantsView> {
  @override
  void initState() {
    super.initState();
    context.read<CourseBloc>().add(CourseParticipantsFetch(widget.courseId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        if (state.status == CourseBlocStatus.loading &&
            state.participants.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == CourseBlocStatus.failure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(state.message ?? 'Failed to load participants'),
                TextButton(
                  onPressed: () => context
                      .read<CourseBloc>()
                      .add(CourseParticipantsFetch(widget.courseId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final participants = state.participants;

        if (participants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No participants yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assign subscriptions to students in the Catalog.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  onPressed: () => context
                      .read<CourseBloc>()
                      .add(CourseParticipantsFetch(widget.courseId)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<CourseBloc>()
                .add(CourseParticipantsFetch(widget.courseId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return _ParticipantTile(participant: participant);
            },
          ),
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final CourseParticipant participant;

  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final progress = participant.progressPercent ?? 0;
    final name = participant.fullName.isNotEmpty
        ? participant.fullName
        : participant.username ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (participant.username != null)
                        Text(
                          participant.username!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                _StatusChip(progressPercent: progress),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(width: 8),
                Text('$progress%'),
              ],
            ),
            if (participant.lastAccessDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last active: ${_formatDate(participant.lastAccessDate!)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final int progressPercent;

  const _StatusChip({required this.progressPercent});

  @override
  Widget build(BuildContext context) {
    if (progressPercent >= 100) {
      return const Chip(
        label: Text('Completed'),
        backgroundColor: Color(0xFFE8F5E9),
        labelStyle: TextStyle(color: Colors.green),
      );
    } else if (progressPercent > 0) {
      return const Chip(
        label: Text('In Progress'),
        backgroundColor: Color(0xFFFFF3E0),
        labelStyle: TextStyle(color: Colors.orange),
      );
    } else {
      return const Chip(
        label: Text('Not Started'),
        backgroundColor: Color(0xFFF5F5F5),
        labelStyle: TextStyle(color: Colors.grey),
      );
    }
  }
}
