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
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';

/// Progress bar widget for course completion
class CourseProgressBar extends StatelessWidget {
  final int progressPercent;
  final int completedLessons;
  final int totalLessons;
  final bool showLabels;

  const CourseProgressBar({
    super.key,
    required this.progressPercent,
    required this.completedLessons,
    required this.totalLessons,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CoursesLocalizations.of(context)!.courses_completedlessonsOfTotallessonsLessons(completedLessons.toString(), totalLessons.toString()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(CoursesLocalizations.of(context)!.courses_progresspercent(progressPercent.toString()),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercent / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (progressPercent >= 100) return Colors.green;
    if (progressPercent >= 50) return Colors.blue;
    return Colors.orange;
  }
}
