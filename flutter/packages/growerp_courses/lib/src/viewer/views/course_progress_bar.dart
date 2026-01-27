/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';

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
              Text(
                '$completedLessons of $totalLessons lessons',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$progressPercent%',
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
