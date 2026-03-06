/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_bloc.dart';

/// Admin view showing participants across ALL courses with search on
/// name, email (username) and course title.
class AllCourseParticipantsView extends StatefulWidget {
  const AllCourseParticipantsView({super.key});

  @override
  State<AllCourseParticipantsView> createState() =>
      _AllCourseParticipantsViewState();
}

class _AllCourseParticipantsViewState
    extends State<AllCourseParticipantsView> {
  final _searchController = TextEditingController();
  String _searchString = '';

  @override
  void initState() {
    super.initState();
    context
        .read<CourseBloc>()
        .add(const CourseAllParticipantsFetch(refresh: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _searchString = value);
    context.read<CourseBloc>().add(
          CourseAllParticipantsFetch(searchString: value, refresh: true),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email or course...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchString.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onSearch,
          ),
        ),
        Expanded(
          child: BlocBuilder<CourseBloc, CourseState>(
            builder: (context, state) {
              if (state.status == CourseBlocStatus.loading &&
                  state.allParticipants.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == CourseBlocStatus.failure) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(state.message ?? 'Failed to load participants'),
                      TextButton(
                        onPressed: () => context.read<CourseBloc>().add(
                              CourseAllParticipantsFetch(
                                  searchString: _searchString, refresh: true),
                            ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final participants = state.allParticipants;

              if (participants.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchString.isEmpty
                            ? 'No participants yet'
                            : 'No results for "$_searchString"',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CourseBloc>().add(
                        CourseAllParticipantsFetch(
                            searchString: _searchString, refresh: true),
                      );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    return _ParticipantTile(
                        participant: participants[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (participant.username != null &&
                          participant.username!.isNotEmpty)
                        Text(
                          participant.username!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      if (participant.courseTitle != null)
                        Text(
                          participant.courseTitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                _ProgressChip(progressPercent: progress),
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
                'Last active: ${_fmt(participant.lastAccessDate!)}',
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

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ProgressChip extends StatelessWidget {
  final int progressPercent;
  const _ProgressChip({required this.progressPercent});

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
