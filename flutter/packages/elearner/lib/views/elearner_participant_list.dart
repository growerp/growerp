/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/growerp_courses.dart';

import 'elearner_participant_dialog.dart';

/// Participant-centric admin list for the elearner app.
///
/// Shows all participants (users enrolled in courses) with their course
/// progress. Each tile represents one participant-course enrollment.
/// - FAB: add new enrollment (create or select participant + choose course)
/// - Tap tile: add another course to the same participant
class ElearnerParticipantList extends StatefulWidget {
  const ElearnerParticipantList({super.key});

  @override
  State<ElearnerParticipantList> createState() =>
      _ElearnerParticipantListState();
}

class _ElearnerParticipantListState extends State<ElearnerParticipantList> {
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

  Future<void> _openDialog(CourseParticipant? participant) async {
    final courseBloc = context.read<CourseBloc>();
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: courseBloc),
        ],
        child: ElearnerParticipantDialog(participant: participant),
      ),
    );
    if (!mounted) return;
    // Refresh list after dialog closes
    courseBloc.add(
      CourseAllParticipantsFetch(searchString: _searchString, refresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coreLocalizations = CoreLocalizations.of(context)!;

    return BlocConsumer<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state.status == CourseBlocStatus.failure) {
          HelperFunctions.showMessage(
            context,
            state.message ?? 'Error',
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        final participants = state.allParticipants;
        final isLoading =
            state.status == CourseBlocStatus.loading && participants.isEmpty;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'participantNew',
            key: const Key('addNew'),
            tooltip: coreLocalizations.addNew,
            onPressed: () => _openDialog(null),
            child: const Icon(Icons.add),
          ),
          body: Column(
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
                child: isLoading
                    ? const Center(child: LoadingIndicator())
                    : participants.isEmpty
                        ? Center(
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
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              context.read<CourseBloc>().add(
                                    CourseAllParticipantsFetch(
                                        searchString: _searchString,
                                        refresh: true),
                                  );
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              itemCount: participants.length,
                              itemBuilder: (context, index) {
                                final participant = participants[index];
                                return _ParticipantTile(
                                  participant: participant,
                                  onTap: () => _openDialog(participant),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final CourseParticipant participant;
  final VoidCallback onTap;

  const _ParticipantTile({required this.participant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = participant.progressPercent ?? 0;
    final name = participant.fullName.isNotEmpty
        ? participant.fullName
        : participant.username ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                      ],
                    ),
                  ),
                  _ProgressChip(progressPercent: progress),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Add another course',
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
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
