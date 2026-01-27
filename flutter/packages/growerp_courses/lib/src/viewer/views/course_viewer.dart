/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_viewer_bloc.dart';

/// In-app course viewer widget for presenting courses
class CourseViewer extends StatelessWidget {
  final String courseId;
  final bool showProgress;

  const CourseViewer({
    super.key,
    required this.courseId,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CourseViewerBloc(restClient: context.read<RestClient>())
            ..add(LoadCourse(courseId)),
      child: CourseViewerContent(showProgress: showProgress),
    );
  }
}

class CourseViewerContent extends StatelessWidget {
  final bool showProgress;

  const CourseViewerContent({super.key, required this.showProgress});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseViewerBloc, CourseViewerState>(
      builder: (context, state) {
        if (state.status == ViewerStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ViewerStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message ?? 'Failed to load course'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (state.course?.courseId != null) {
                      context.read<CourseViewerBloc>().add(
                            LoadCourse(state.course!.courseId!),
                          );
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.course == null) {
          return const Center(child: Text('Course not found'));
        }

        return _buildViewer(context, state);
      },
    );
  }

  Widget _buildViewer(BuildContext context, CourseViewerState state) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

    if (isNarrow) {
      return _buildMobileViewer(context, state);
    }

    return Row(
      children: [
        SizedBox(width: 300, child: _buildSidebar(context, state)),
        const VerticalDivider(width: 1),
        Expanded(child: _buildContent(context, state)),
      ],
    );
  }

  Widget _buildMobileViewer(BuildContext context, CourseViewerState state) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.course!.title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.menu_book), text: 'Content'),
              Tab(icon: Icon(Icons.list), text: 'Outline'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContent(context, state),
            _buildSidebar(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, CourseViewerState state) {
    final course = state.course!;
    final modules = course.modules ?? [];

    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress) _buildProgressHeader(context, state),
          Expanded(
            child: ListView.builder(
              itemCount: modules.length,
              itemBuilder: (context, moduleIndex) {
                final module = modules[moduleIndex];
                return ExpansionTile(
                  initiallyExpanded: moduleIndex == 0,
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text(
                      '${moduleIndex + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(
                    module.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: (module.lessons ?? []).map((lesson) {
                    final isSelected =
                        state.currentLesson?.lessonId == lesson.lessonId;
                    final isCompleted =
                        state.progress?.isLessonCompleted(lesson.lessonId!) ??
                            false;

                    return ListTile(
                      selected: isSelected,
                      leading: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.play_circle_outline,
                        color: isCompleted ? Colors.green : null,
                      ),
                      title: Text(lesson.title),
                      subtitle: lesson.estimatedDuration != null
                          ? Text('${lesson.estimatedDuration} min')
                          : null,
                      onTap: () {
                        context.read<CourseViewerBloc>().add(
                              SelectLesson(lesson),
                            );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context, CourseViewerState state) {
    final progress = state.progress?.progressPercent ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: Theme.of(context).textTheme.titleSmall),
              Text(
                '$progress%',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CourseViewerState state) {
    final lesson = state.currentLesson;

    if (lesson == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a lesson to begin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (lesson.estimatedDuration != null)
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text('${lesson.estimatedDuration} minutes'),
              ],
            ),
          const SizedBox(height: 24),
          if (lesson.content != null && lesson.content!.isNotEmpty)
            MarkdownBody(data: lesson.content!, selectable: true)
          else
            const Text('No content available for this lesson.'),
          const SizedBox(height: 32),
          _buildLessonActions(context, state, lesson),
        ],
      ),
    );
  }

  Widget _buildLessonActions(
    BuildContext context,
    CourseViewerState state,
    CourseLesson lesson,
  ) {
    final isCompleted =
        state.progress?.isLessonCompleted(lesson.lessonId!) ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_getPreviousLesson(state) != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            onPressed: () {
              final prev = _getPreviousLesson(state);
              if (prev != null) {
                context.read<CourseViewerBloc>().add(SelectLesson(prev));
              }
            },
          )
        else
          const SizedBox(),
        ElevatedButton.icon(
          icon: Icon(isCompleted ? Icons.check : Icons.check_circle_outline),
          label: Text(isCompleted ? 'Completed' : 'Mark as Complete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompleted ? Colors.green : null,
          ),
          onPressed: isCompleted
              ? null
              : () {
                  context.read<CourseViewerBloc>().add(
                        MarkLessonComplete(lesson.lessonId!),
                      );
                },
        ),
        if (_getNextLesson(state) != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            onPressed: () {
              final next = _getNextLesson(state);
              if (next != null) {
                context.read<CourseViewerBloc>().add(SelectLesson(next));
              }
            },
          )
        else
          const SizedBox(),
      ],
    );
  }

  CourseLesson? _getPreviousLesson(CourseViewerState state) {
    final allLessons = _getAllLessons(state.course);
    final currentIndex = allLessons.indexWhere(
      (l) => l.lessonId == state.currentLesson?.lessonId,
    );
    if (currentIndex > 0) {
      return allLessons[currentIndex - 1];
    }
    return null;
  }

  CourseLesson? _getNextLesson(CourseViewerState state) {
    final allLessons = _getAllLessons(state.course);
    final currentIndex = allLessons.indexWhere(
      (l) => l.lessonId == state.currentLesson?.lessonId,
    );
    if (currentIndex >= 0 && currentIndex < allLessons.length - 1) {
      return allLessons[currentIndex + 1];
    }
    return null;
  }

  List<CourseLesson> _getAllLessons(Course? course) {
    if (course == null) return [];
    final lessons = <CourseLesson>[];
    for (final module in course.modules ?? []) {
      lessons.addAll(module.lessons ?? []);
    }
    return lessons;
  }
}
