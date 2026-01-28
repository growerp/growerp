/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_bloc.dart';
import 'course_dialog.dart';
import 'generate_media_dialog.dart';

class CourseList extends StatelessWidget {
  const CourseList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseBloc(restClient: context.read<RestClient>())
        ..add(const CourseFetch(refresh: true)),
      child: const CourseListView(),
    );
  }
}

class CourseListView extends StatefulWidget {
  const CourseListView({super.key});

  @override
  State<CourseListView> createState() => _CourseListViewState();
}

class _CourseListViewState extends State<CourseListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CourseBloc>().add(const CourseFetch());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state.status == CourseBlocStatus.failure && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (state.status == CourseBlocStatus.success && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            key: const Key('addCourse'),
            onPressed: () => _showCourseDialog(context),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildCourseList(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        key: const Key('searchCourse'),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search courses...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CourseBloc>().add(
                          const CourseFetch(refresh: true),
                        );
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onSubmitted: (value) {
          context.read<CourseBloc>().add(
                CourseFetch(searchString: value, refresh: true),
              );
        },
      ),
    );
  }

  Widget _buildCourseList(CourseState state) {
    if (state.status == CourseBlocStatus.initial ||
        (state.status == CourseBlocStatus.loading && state.courses.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Create your first course to get started'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CourseBloc>().add(const CourseFetch(refresh: true));
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.hasReachedMax
            ? state.courses.length
            : state.courses.length + 1,
        itemBuilder: (context, index) {
          if (index >= state.courses.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildCourseCard(state.courses[index]);
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        key: Key('course_${course.pseudoId}'),
        leading: CircleAvatar(
          backgroundColor: _getDifficultyColor(course.difficulty),
          child: const Icon(Icons.school, color: Colors.white),
        ),
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.description != null)
              Text(
                course.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(course.status),
                const SizedBox(width: 8),
                if (course.estimatedDuration != null)
                  Text(
                    '${course.estimatedDuration} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(width: 8),
                Text(
                  '${course.modules?.length ?? 0} modules',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                Text(
                  '${course.modules?.fold<int>(0, (sum, m) => sum + (m.lessons?.length ?? 0)) ?? 0} lessons',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          key: Key('menu_${course.pseudoId}'),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showCourseDialog(context, course: course);
                break;
              case 'delete':
                _confirmDelete(context, course);
                break;
              case 'generate':
                _showGenerateMediaDialog(context, course);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'generate',
              child: ListTile(
                leading: Icon(Icons.auto_awesome),
                title: Text('Generate Media'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showCourseDialog(context, course: course),
      ),
    );
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

  Widget _buildStatusChip(CourseStatus? status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  void _showCourseDialog(BuildContext context, {Course? course}) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CourseBloc>(),
        child: CourseDialog(course: course),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.title}"?\n\n'
          'This will also delete all modules, lessons, and generated media.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CourseBloc>().add(CourseDelete(course));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showGenerateMediaDialog(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CourseBloc>(),
        child: GenerateMediaDialog(course: course),
      ),
    );
  }
}
