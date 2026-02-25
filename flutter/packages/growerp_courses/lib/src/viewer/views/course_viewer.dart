/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_viewer_bloc.dart';
import '../../media/views/media_preview.dart';

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

class CourseViewerContent extends StatefulWidget {
  final bool showProgress;

  const CourseViewerContent({super.key, required this.showProgress});

  @override
  State<CourseViewerContent> createState() => _CourseViewerContentState();
}

class _CourseViewerContentState extends State<CourseViewerContent> {
  final ScrollController _sidebarScrollController = ScrollController();
  final Map<String, GlobalKey> _lessonKeys = {};
  final Map<int, ExpansibleController> _moduleControllers = {};

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    super.dispose();
  }

  GlobalKey _getLessonKey(String lessonId) =>
      _lessonKeys.putIfAbsent(lessonId, () => GlobalKey());

  ExpansibleController _getModuleController(int index) =>
      _moduleControllers.putIfAbsent(index, () => ExpansibleController());

  /// Expands the module that contains the current lesson, then scrolls to it.
  void _ensureLessonVisible(CourseViewerState state) {
    final lesson = state.currentLesson;
    if (lesson?.lessonId == null || state.course?.modules == null) return;

    final modules = state.course!.modules!;
    for (int i = 0; i < modules.length; i++) {
      final lessons = modules[i].lessons ?? [];
      if (lessons.any((l) => l.lessonId == lesson!.lessonId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            _moduleControllers[i]?.expand();
          } catch (_) {}
          // Defer the scroll until after expand()'s layout + semantics pass
          // have fully completed. A nested addPostFrameCallback fires during
          // the semantics update of the same frame, which causes a layout
          // assertion on dirty render objects. Future.delayed(Duration.zero)
          // schedules the scroll on the *next* event-loop turn, after the
          // current frame (including layout, paint, and semantics) is done.
          Future.delayed(Duration.zero, () {
            if (!mounted) return;
            final key = _lessonKeys[lesson!.lessonId];
            final ctx = key?.currentContext;
            if (ctx != null) {
              // ignore: use_build_context_synchronously
              Scrollable.ensureVisible(
                ctx,
                alignment: 0.3,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseViewerBloc, CourseViewerState>(
      listenWhen: (prev, curr) =>
          prev.currentLesson?.lessonId != curr.currentLesson?.lessonId,
      listener: (context, state) => _ensureLessonVisible(state),
      builder: (context, state) {
        if (state.status == ViewerStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ViewerStatus.selectingCourse) {
          return _buildCourseSelector(context, state);
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
                    } else {
                      context.read<CourseViewerBloc>().add(
                        const FetchAvailableCourses(),
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

  Widget _buildCourseSelector(BuildContext context, CourseViewerState state) {
    final courses = state.availableCourses;

    return Scaffold(
      appBar: AppBar(title: const Text('Select a Course'), centerTitle: true),
      body: courses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No courses available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a course first to start learning',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a course to begin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 350,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _buildCourseCard(context, course);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final moduleCount = course.modules?.length ?? 0;
    final lessonCount =
        course.modules?.fold<int>(
          0,
          (sum, m) => sum + (m.lessons?.length ?? 0),
        ) ??
        0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (course.courseId != null) {
            context.read<CourseViewerBloc>().add(LoadCourse(course.courseId!));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.school,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (course.description != null)
                Expanded(
                  child: Text(
                    course.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.view_module,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$moduleCount modules',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.play_lesson,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$lessonCount lessons',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        if (state.mediaList.isNotEmpty) ...[
          const VerticalDivider(width: 1),
          SizedBox(width: 280, child: _buildMediaPanel(context, state)),
        ],
      ],
    );
  }

  Widget _buildMobileViewer(BuildContext context, CourseViewerState state) {
    final hasMedia = state.mediaList.isNotEmpty;
    return DefaultTabController(
      length: hasMedia ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.course!.title),
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.menu_book), text: 'Content'),
              const Tab(icon: Icon(Icons.list), text: 'Outline'),
              if (hasMedia)
                Tab(
                  icon: Badge(
                    label: Text('${state.mediaList.length}'),
                    child: const Icon(Icons.video_library),
                  ),
                  text: 'Media',
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContent(context, state),
            _buildSidebar(context, state),
            if (hasMedia) _buildMediaTab(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, CourseViewerState state) {
    final course = state.course!;
    final modules = course.modules ?? [];
    final currentLessonId = state.currentLesson?.lessonId;

    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showProgress) _buildProgressHeader(context, state),
          Expanded(
            child: ListView.builder(
              controller: _sidebarScrollController,
              itemCount: modules.length,
              itemBuilder: (context, moduleIndex) {
                final module = modules[moduleIndex];
                final isCurrentModule =
                    currentLessonId != null &&
                    (module.lessons?.any(
                          (l) => l.lessonId == currentLessonId,
                        ) ??
                        false);
                return ExpansionTile(
                  controller: _getModuleController(moduleIndex),
                  initiallyExpanded:
                      isCurrentModule ||
                      (currentLessonId == null && moduleIndex == 0),
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
                      key: lesson.lessonId != null
                          ? _getLessonKey(lesson.lessonId!)
                          : null,
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

  /// Build the media panel for desktop view (right sidebar)
  Widget _buildMediaPanel(BuildContext context, CourseViewerState state) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.video_library, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Generated Media',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '${state.mediaList.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: state.mediaList.length,
              itemBuilder: (context, index) {
                final media = state.mediaList[index];
                return _buildMediaListItem(context, media);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the media tab for mobile view
  Widget _buildMediaTab(BuildContext context, CourseViewerState state) {
    if (state.mediaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No media available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.mediaList.length,
      itemBuilder: (context, index) {
        final media = state.mediaList[index];
        return _buildMediaCard(context, media);
      },
    );
  }

  /// Build a media list item for the sidebar
  Widget _buildMediaListItem(BuildContext context, CourseMedia media) {
    return ListTile(
      leading: _getPlatformIcon(media.platform),
      title: Text(
        media.title ?? _getPlatformLabel(media.platform),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          _buildStatusChip(media.status),
          if (media.mediaType != null) ...[
            const SizedBox(width: 4),
            Text(
              _getMediaTypeLabel(media.mediaType!),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
      onTap: () => _showMediaPreview(context, media),
    );
  }

  /// Build a media card for the mobile tab
  Widget _buildMediaCard(BuildContext context, CourseMedia media) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMediaPreview(context, media),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPlatformColor(
                    media.platform,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _getPlatformIcon(media.platform),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title ?? _getPlatformLabel(media.platform),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(media.status),
                        const SizedBox(width: 8),
                        if (media.mediaType != null)
                          Text(
                            _getMediaTypeLabel(media.mediaType!),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaPreview(BuildContext context, CourseMedia media) {
    showDialog(
      context: context,
      builder: (context) => MediaPreview(media: media),
    );
  }

  Icon _getPlatformIcon(MediaPlatform? platform) {
    switch (platform) {
      case MediaPlatform.youtube:
        return const Icon(Icons.play_circle_fill, color: Colors.red);
      case MediaPlatform.linkedin:
        return const Icon(Icons.work, color: Color(0xFF0077B5));
      case MediaPlatform.twitter:
        return const Icon(Icons.tag, color: Color(0xFF1DA1F2));
      case MediaPlatform.medium:
        return const Icon(Icons.article, color: Colors.black);
      case MediaPlatform.email:
        return const Icon(Icons.email, color: Colors.orange);
      case MediaPlatform.substack:
        return const Icon(Icons.newspaper, color: Colors.deepOrange);
      case MediaPlatform.inapp:
        return const Icon(Icons.phone_android, color: Colors.blue);
      default:
        return const Icon(Icons.content_copy);
    }
  }

  String _getPlatformLabel(MediaPlatform? platform) {
    switch (platform) {
      case MediaPlatform.youtube:
        return 'YouTube Script';
      case MediaPlatform.linkedin:
        return 'LinkedIn Post';
      case MediaPlatform.twitter:
        return 'Twitter Thread';
      case MediaPlatform.medium:
        return 'Medium Article';
      case MediaPlatform.email:
        return 'Email Sequence';
      case MediaPlatform.substack:
        return 'Substack Post';
      case MediaPlatform.inapp:
        return 'In-App Tutorial';
      default:
        return 'Content';
    }
  }

  Color _getPlatformColor(MediaPlatform? platform) {
    switch (platform) {
      case MediaPlatform.youtube:
        return Colors.red;
      case MediaPlatform.linkedin:
        return const Color(0xFF0077B5);
      case MediaPlatform.twitter:
        return const Color(0xFF1DA1F2);
      case MediaPlatform.medium:
        return Colors.black;
      case MediaPlatform.email:
        return Colors.orange;
      case MediaPlatform.substack:
        return Colors.deepOrange;
      case MediaPlatform.inapp:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getMediaTypeLabel(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.post:
        return 'Post';
      case MediaType.article:
        return 'Article';
      case MediaType.sequence:
        return 'Sequence';
      case MediaType.script:
        return 'Script';
      case MediaType.thread:
        return 'Thread';
      case MediaType.tutorial:
        return 'Tutorial';
    }
  }

  Widget _buildStatusChip(MediaStatus? status) {
    Color color;
    String label;
    switch (status) {
      case MediaStatus.published:
        color = Colors.green;
        label = 'PUBLISHED';
        break;
      case MediaStatus.scheduled:
        color = Colors.blue;
        label = 'SCHEDULED';
        break;
      case MediaStatus.reviewed:
        color = Colors.orange;
        label = 'REVIEWED';
        break;
      default:
        color = Colors.grey;
        label = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
