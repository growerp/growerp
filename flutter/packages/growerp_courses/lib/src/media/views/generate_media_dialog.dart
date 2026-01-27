/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_media_bloc.dart';

/// Dialog for generating AI content from a course
class GenerateMediaDialog extends StatefulWidget {
  final Course course;

  const GenerateMediaDialog({super.key, required this.course});

  @override
  State<GenerateMediaDialog> createState() => _GenerateMediaDialogState();
}

class _GenerateMediaDialogState extends State<GenerateMediaDialog> {
  final Set<MediaPlatform> _selectedPlatforms = {};
  CourseModule? _selectedModule;
  CourseLesson? _selectedLesson;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CourseMediaBloc(restClient: context.read<RestClient>()),
      child: BlocConsumer<CourseMediaBloc, CourseMediaState>(
        listener: (context, state) {
          if (state.status == MediaBlocStatus.success &&
              state.generatedMedia != null) {
            // Show generated content preview
            Navigator.pop(context, state.generatedMedia);
          }
          if (state.status == MediaBlocStatus.failure &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Dialog(
            child: Container(
              width: 500,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Generate AI Content'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                body: state.status == MediaBlocStatus.generating
                    ? _buildGeneratingState()
                    : _buildForm(context, state),
                bottomNavigationBar: state.status == MediaBlocStatus.generating
                    ? null
                    : _buildActionButtons(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating content...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, CourseMediaState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseInfo(),
          const SizedBox(height: 24),
          _buildPlatformSelection(),
          const SizedBox(height: 24),
          _buildScopeSelection(),
        ],
      ),
    );
  }

  Widget _buildCourseInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(
              widget.course.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.course.description != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.course.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Platforms', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MediaPlatform.values.map((platform) {
            final isSelected = _selectedPlatforms.contains(platform);
            return FilterChip(
              selected: isSelected,
              label: Text(_getPlatformLabel(platform)),
              avatar: Icon(_getPlatformIcon(platform), size: 18),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPlatforms.add(platform);
                  } else {
                    _selectedPlatforms.remove(platform);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScopeSelection() {
    final modules = widget.course.modules ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Scope (optional)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CourseModule?>(
          initialValue: _selectedModule,
          decoration: const InputDecoration(
            labelText: 'Module',
            border: OutlineInputBorder(),
            hintText: 'Entire course',
          ),
          items: [
            const DropdownMenuItem<CourseModule?>(
              value: null,
              child: Text('Entire course'),
            ),
            ...modules.map(
              (module) =>
                  DropdownMenuItem(value: module, child: Text(module.title)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedModule = value;
              _selectedLesson = null;
            });
          },
        ),
        if (_selectedModule != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<CourseLesson?>(
            initialValue: _selectedLesson,
            decoration: const InputDecoration(
              labelText: 'Lesson',
              border: OutlineInputBorder(),
              hintText: 'Entire module',
            ),
            items: [
              const DropdownMenuItem<CourseLesson?>(
                value: null,
                child: Text('Entire module'),
              ),
              ...(_selectedModule!.lessons ?? []).map(
                (lesson) =>
                    DropdownMenuItem(value: lesson, child: Text(lesson.title)),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedLesson = value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate'),
            onPressed: _selectedPlatforms.isEmpty ? null : _generate,
          ),
        ],
      ),
    );
  }

  void _generate() {
    for (final platform in _selectedPlatforms) {
      context.read<CourseMediaBloc>().add(
            MediaGenerate(
              courseId: widget.course.courseId!,
              platform: platform,
              moduleId: _selectedModule?.moduleId,
              lessonId: _selectedLesson?.lessonId,
            ),
          );
    }
  }

  String _getPlatformLabel(MediaPlatform platform) {
    switch (platform) {
      case MediaPlatform.linkedin:
        return 'LinkedIn';
      case MediaPlatform.medium:
        return 'Medium';
      case MediaPlatform.email:
        return 'Email';
      case MediaPlatform.youtube:
        return 'YouTube';
      case MediaPlatform.twitter:
        return 'Twitter/X';
      case MediaPlatform.substack:
        return 'Substack';
      case MediaPlatform.inapp:
        return 'In-App Tutorial';
    }
  }

  IconData _getPlatformIcon(MediaPlatform platform) {
    switch (platform) {
      case MediaPlatform.linkedin:
        return Icons.work_outline;
      case MediaPlatform.medium:
        return Icons.article_outlined;
      case MediaPlatform.email:
        return Icons.email_outlined;
      case MediaPlatform.youtube:
        return Icons.play_circle_outline;
      case MediaPlatform.twitter:
        return Icons.alternate_email;
      case MediaPlatform.substack:
        return Icons.rss_feed;
      case MediaPlatform.inapp:
        return Icons.help_outline;
    }
  }
}
