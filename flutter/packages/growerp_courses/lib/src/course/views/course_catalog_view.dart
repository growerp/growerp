/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/course_bloc.dart';
import '../../viewer/bloc/course_viewer_bloc.dart';
import '../../viewer/views/course_viewer.dart';
import 'course_payment_dialog.dart';

/// Customer view that shows ALL published courses with a "Subscribed" badge
/// on courses the current user has an active subscription for.
class CourseCatalogView extends StatefulWidget {
  const CourseCatalogView({super.key});

  @override
  State<CourseCatalogView> createState() => _CourseCatalogViewState();
}

class _CourseCatalogViewState extends State<CourseCatalogView> {
  @override
  void initState() {
    super.initState();
    context.read<CourseBloc>().add(const CourseFetch(refresh: true));
    context.read<CourseViewerBloc>().add(const FetchAvailableCourses());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, courseState) {
        return BlocBuilder<CourseViewerBloc, CourseViewerState>(
          builder: (context, viewerState) {
            if (courseState.status == CourseBlocStatus.loading &&
                courseState.courses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (courseState.status == CourseBlocStatus.failure) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(courseState.message ?? 'Failed to load courses'),
                    TextButton(
                      onPressed: () => context
                          .read<CourseBloc>()
                          .add(const CourseFetch(refresh: true)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (courseState.courses.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No courses available yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final subscribedIds = <String>{
              for (final c in viewerState.availableCourses)
                if (c.courseId != null) c.courseId!,
            };

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<CourseBloc>()
                    .add(const CourseFetch(refresh: true));
                context
                    .read<CourseViewerBloc>()
                    .add(const FetchAvailableCourses());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: courseState.courses.length,
                itemBuilder: (context, index) {
                  final course = courseState.courses[index];
                  final isSubscribed = course.courseId != null &&
                      subscribedIds.contains(course.courseId);
                  return _CourseCatalogTile(
                    course: course,
                    isSubscribed: isSubscribed,
                    onOpen: () => _openCourse(context, course.courseId!),
                    onSubscribe: () => _showPaymentDialog(context, course),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, Course course) {
    showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseBloc>(),
        child: CoursePaymentDialog(course: course),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<CourseViewerBloc>().add(const FetchAvailableCourses());
      }
    });
  }

  void _openCourse(BuildContext context, String courseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CourseViewerBloc>()),
          ],
          child: CourseViewer(courseId: courseId),
        ),
      ),
    );
  }
}

class _CourseCatalogTile extends StatelessWidget {
  final Course course;
  final bool isSubscribed;
  final VoidCallback onOpen;
  final VoidCallback onSubscribe;

  const _CourseCatalogTile({
    required this.course,
    required this.isSubscribed,
    required this.onOpen,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: isSubscribed ? onOpen : onSubscribe,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: course.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          course.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.school, size: 40),
                        ),
                      )
                    : const Icon(Icons.school, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (isSubscribed)
                          Chip(
                            label: const Text('Subscribed'),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontSize: 12,
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    if (course.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (course.difficulty != null)
                          _DifficultyBadge(difficulty: course.difficulty!),
                        if (course.estimatedDuration != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.schedule,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            '${course.estimatedDuration} min',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                        const Spacer(),
                        if (isSubscribed)
                          TextButton.icon(
                            onPressed: onOpen,
                            icon: const Icon(Icons.play_circle_outline,
                                size: 16),
                            label: const Text('Open'),
                          )
                        else ...[
                          Text(
                            course.price != null &&
                                    course.price!.toDouble() > 0
                                ? '\$${course.price!.toStringAsFixed(2)}'
                                : 'Free',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: course.price != null &&
                                          course.price!.toDouble() > 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: onSubscribe,
                            icon: const Icon(Icons.lock_outline, size: 16),
                            label: const Text('Subscribe'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

class _DifficultyBadge extends StatelessWidget {
  final CourseDifficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  String get _label {
    if (difficulty == CourseDifficulty.beginner) return 'Beginner';
    if (difficulty == CourseDifficulty.intermediate) return 'Intermediate';
    return 'Advanced';
  }

  Color get _color {
    if (difficulty == CourseDifficulty.beginner) return Colors.green;
    if (difficulty == CourseDifficulty.intermediate) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
