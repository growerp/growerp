/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';

/// Course detail view showing modules and lessons
class CourseDetail extends StatelessWidget {
  final String courseId;

  const CourseDetail({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Detail')),
      body: Center(child: Text('Course Detail - $courseId')),
    );
  }
}
