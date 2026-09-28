/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';

import '../bloc/course_learner_bloc.dart';
import 'participant_dialog.dart';

/// The CourseLearnerBloc emits message keys; anything else (a backend error)
/// is shown as it is.
String translateLearnerMessage(BuildContext context, String message) {
  final l = CoursesLocalizations.of(context)!;
  return switch (message) {
    'learnerAddSuccess' => l.courses_learnerAddSuccess,
    'learnerUpdateSuccess' => l.courses_learnerUpdateSuccess,
    'learnerCourseAssigned' => l.courses_learnerCourseAssigned,
    'learnerCourseRemoved' => l.courses_learnerCourseRemoved,
    _ => message,
  };
}

/// Admin: the persons following at least one course, to add and change them
/// and assign or remove their courses
class CourseParticipantList extends StatelessWidget {
  const CourseParticipantList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CourseLearnerBloc(restClient: context.read<RestClient>())
            ..add(const CourseLearnerFetch(refresh: true)),
      child: const CourseParticipantListView(),
    );
  }
}

class CourseParticipantListView extends StatefulWidget {
  const CourseParticipantListView({super.key});

  @override
  State<CourseParticipantListView> createState() =>
      _CourseParticipantListViewState();
}

class _CourseParticipantListViewState extends State<CourseParticipantListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late CourseLearnerBloc _bloc;
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CourseLearnerBloc>();
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max * 0.9) {
      _bloc.add(CourseLearnerFetch(searchString: _bloc.state.searchString));
    }
  }

  Future<void> _openDialog(CourseLearner? learner) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) => BlocProvider.value(
        value: _bloc,
        child: ParticipantDialog(learner: learner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = CoursesLocalizations.of(context)!;
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    return BlocConsumer<CourseLearnerBloc, CourseLearnerState>(
      // the open dialog shows its own messages
      listenWhen: (previous, current) =>
          ModalRoute.of(context)?.isCurrent ?? true,
      listener: (context, state) {
        if (state.status == CourseLearnerStatus.failure) {
          HelperFunctions.showMessage(
            context,
            translateLearnerMessage(context, state.message ?? ''),
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        if (state.status == CourseLearnerStatus.failure &&
            state.learners.isEmpty) {
          return FatalErrorForm(message: l.courses_failedToLoadParticipants);
        }
        final learners = state.learners;
        return Column(
          children: [
            ListFilterBar(
              searchHint: l.courses_searchParticipantsHint,
              searchController: _searchController,
              onSearchChanged: (value) => _bloc.add(
                CourseLearnerFetch(searchString: value, refresh: true),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    columns: _columns(context),
                    rows: [
                      for (var i = 0; i < learners.length; i++)
                        _row(context, learners[i], i),
                    ],
                    isLoading:
                        state.status == CourseLearnerStatus.loading &&
                        learners.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 72 : 56,
                    onRowTap: (index) => _openDialog(learners[index]),
                  ),
                  if (learners.isEmpty &&
                      state.status == CourseLearnerStatus.success)
                    Center(
                      child: Text(
                        l.courses_noParticipantsYet,
                        key: const Key('empty'),
                      ),
                    ),
                  Positioned(
                    right: right,
                    bottom: bottom,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          right = right! - details.delta.dx;
                          bottom -= details.delta.dy;
                        });
                      },
                      child: FloatingActionButton(
                        heroTag: 'participantNew',
                        key: const Key('addNewParticipant'),
                        onPressed: () => _openDialog(null),
                        tooltip: l.courses_learnerAdd,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    final l = CoursesLocalizations.of(context)!;
    if (isAPhone(context)) {
      return [
        StyledColumn(header: '', flex: 1),
        StyledColumn(header: l.courses_tableHdrName, flex: 4),
        StyledColumn(header: l.courses_tableHdrCourses, flex: 2),
      ];
    }
    return [
      StyledColumn(header: l.courses_tableHdrId, flex: 1),
      StyledColumn(header: l.courses_tableHdrName, flex: 3),
      StyledColumn(header: l.courses_tableHdrEmail, flex: 3),
      StyledColumn(header: l.courses_tableHdrCourses, flex: 3),
      StyledColumn(header: l.courses_tableHdrProgress, flex: 1),
    ];
  }

  List<Widget> _row(BuildContext context, CourseLearner learner, int index) {
    final courseTitles = learner.courses.map((c) => c.title ?? '').join(', ');
    final progress = learner.courses.isEmpty
        ? 0
        : learner.courses.fold<int>(
                0,
                (sum, c) => sum + (c.progressPercent ?? 0),
              ) ~/
              learner.courses.length;
    if (isAPhone(context)) {
      return [
        CircleAvatar(
          key: Key('participantItem$index'),
          child: Text(
            learner.fullName.isNotEmpty
                ? learner.fullName[0].toUpperCase()
                : '?',
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              learner.fullName,
              key: Key('name$index'),
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              learner.email ?? '',
              key: Key('email$index'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Text(
          '${learner.courses.length}',
          key: Key('courses$index'),
          textAlign: TextAlign.center,
        ),
      ];
    }
    return [
      Text(
        learner.pseudoId ?? '',
        key: Key('participantItem$index'),
      ),
      Text(learner.fullName, key: Key('name$index')),
      Text(learner.email ?? '', key: Key('email$index')),
      Text(
        courseTitles,
        key: Key('courses$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      Text('$progress%', key: Key('progress$index')),
    ];
  }
}
