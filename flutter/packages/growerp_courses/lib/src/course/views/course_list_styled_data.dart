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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/course_bloc.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';

/// Returns column definitions for course list based on device type
List<StyledColumn> getCourseListColumns(BuildContext context) {
  final localizations = CoursesLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      StyledColumn(header: '', flex: 1), // Icon
      StyledColumn(header: localizations.courses_tableHdrInfo, flex: 4),
      StyledColumn(header: localizations.courses_tableHdrStatus, flex: 2),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return [
    StyledColumn(header: localizations.courses_tableHdrId, flex: 1),
    StyledColumn(header: localizations.courses_tableHdrTitle, flex: 3),
    StyledColumn(header: localizations.courses_tableHdrDescription, flex: 3),
    StyledColumn(header: localizations.courses_tableHdrDifficulty, flex: 1),
    StyledColumn(header: localizations.courses_tableHdrDuration, flex: 1),
    StyledColumn(header: localizations.courses_tableHdrStatus, flex: 1),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for course list
List<Widget> getCourseListRow({
  required BuildContext context,
  required Course course,
  required int index,
  required CourseBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  List<Widget> cells = [];

  if (isPhone) {
    // Icon
    cells.add(
      CircleAvatar(
        key: Key('courseAvatar$index'),
        backgroundColor: _getDifficultyColor(course.difficulty),
        child: const Icon(Icons.school, color: Colors.white, size: 20),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('courseInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            course.title,
            key: Key('title$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (course.pseudoId != null)
            Text(
              course.pseudoId!,
              key: Key('id$index'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          Row(
            children: [
              Text(
                CoursesLocalizations.of(context)!.courses_coursemoduleslength0M(
                  (course.modules?.length ?? 0).toString(),
                ),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CoursesLocalizations.of(
                  context,
                )!.courses_coursemodulesfoldint0summsummlessonslength00L(
                  (course.modules?.fold<int>(
                            0,
                            (sum, m) => sum + (m.lessons?.length ?? 0),
                          ) ??
                          0)
                      .toString(),
                ),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Status chip
    cells.add(_buildStatusChip(context, course.status));
  } else {
    // ID
    cells.add(Text(course.pseudoId ?? '', key: Key('id$index')));

    // Title
    cells.add(
      Text(
        course.title,
        key: Key('title$index'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );

    // Description
    cells.add(
      Text(
        course.description ?? '',
        key: Key('desc$index'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // Difficulty
    cells.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _getDifficultyColor(course.difficulty).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getDifficultyLabel(course.difficulty),
          key: Key('difficulty$index'),
          style: TextStyle(
            fontSize: 11,
            color: _getDifficultyColor(course.difficulty),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    // Duration
    cells.add(
      Text(
        course.estimatedDuration != null ? '${course.estimatedDuration}m' : '-',
        key: Key('duration$index'),
        textAlign: TextAlign.center,
      ),
    );

    // Status
    cells.add(_buildStatusChip(context, course.status));
  }

  // Delete action
  cells.add(
    PopupMenuButton<String>(
      key: Key('menu$index'),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'delete') {
          bloc.add(CourseDelete(course));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ),
  );

  return cells;
}

Color _getDifficultyColor(CourseDifficulty? difficulty) {
  switch (difficulty) {
    case CourseDifficulty.beginner:
      return Colors.green;
    case CourseDifficulty.intermediate:
      return Colors.orange;
    case CourseDifficulty.advanced:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _getDifficultyLabel(CourseDifficulty? difficulty) {
  switch (difficulty) {
    case CourseDifficulty.beginner:
      return 'Beginner';
    case CourseDifficulty.intermediate:
      return 'Intermediate';
    case CourseDifficulty.advanced:
      return 'Advanced';
    default:
      return '-';
  }
}

Widget _buildStatusChip(BuildContext context, CourseStatus? status) {
  Color color;
  String label;
  switch (status) {
    case CourseStatus.published:
      color = Colors.green;
      label = 'Published';
      break;
    case CourseStatus.draft:
      color = Colors.orange;
      label = 'Draft';
      break;
    default:
      color = Colors.grey;
      label = 'Draft';
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 1),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );
}
