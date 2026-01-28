/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_bloc.dart';

/// Dialog for generating AI-powered media content from course material
class GenerateMediaDialog extends StatefulWidget {
  final Course course;

  const GenerateMediaDialog({super.key, required this.course});

  @override
  State<GenerateMediaDialog> createState() => _GenerateMediaDialogState();
}

class _GenerateMediaDialogState extends State<GenerateMediaDialog> {
  MediaPlatform? _selectedPlatform;
  MediaType? _selectedMediaType;
  String? _selectedModuleId;
  String? _selectedLessonId;
  bool _isGenerating = false;
  String? _generatedContent;
  String? _errorMessage;

  // Platform-specific media type mappings
  static const Map<MediaPlatform, List<MediaType>> _platformMediaTypes = {
    MediaPlatform.linkedin: [
      MediaType.post,
      MediaType.article,
      MediaType.sequence
    ],
    MediaPlatform.medium: [MediaType.article, MediaType.tutorial],
    MediaPlatform.email: [MediaType.sequence],
    MediaPlatform.youtube: [MediaType.script],
    MediaPlatform.twitter: [MediaType.thread, MediaType.post],
    MediaPlatform.substack: [MediaType.article],
    MediaPlatform.inapp: [MediaType.tutorial],
  };

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state.status == CourseBlocStatus.success && _isGenerating) {
          setState(() {
            _isGenerating = false;
            if (state.message != null) {
              // Success - show generated content or success message
              _generatedContent = state.message;
            }
          });
        } else if (state.status == CourseBlocStatus.failure && _isGenerating) {
          setState(() {
            _isGenerating = false;
            _errorMessage = state.message ?? 'Failed to generate content';
          });
        }
      },
      child: Dialog(
        child: Container(
          width: 700,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Generate Media Content'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseInfo(),
                  const SizedBox(height: 24),
                  _buildScopeSelector(),
                  const SizedBox(height: 24),
                  _buildPlatformSelector(),
                  const SizedBox(height: 24),
                  if (_selectedPlatform != null) _buildMediaTypeSelector(),
                  if (_generatedContent != null) ...[
                    const SizedBox(height: 24),
                    _buildGeneratedContent(),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    _buildErrorMessage(),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: _buildActionButtons(),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.5),
            Theme.of(context)
                .colorScheme
                .secondaryContainer
                .withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.school,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.view_module,
                      '${widget.course.modules?.length ?? 0} modules',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.play_lesson,
                      '${widget.course.modules?.fold<int>(0, (sum, m) => sum + (m.lessons?.length ?? 0)) ?? 0} lessons',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildScopeSelector() {
    final modules = widget.course.modules ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Scope',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select what content to use for media generation',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          key: const Key('scopeModule'),
          decoration: InputDecoration(
            labelText: 'Module (optional)',
            hintText: 'All modules',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.view_module),
          ),
          initialValue: _selectedModuleId,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All modules (entire course)'),
            ),
            ...modules.map((m) => DropdownMenuItem(
                  value: m.moduleId,
                  child: Text(m.title),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedModuleId = value;
              _selectedLessonId = null;
            });
          },
        ),
        if (_selectedModuleId != null) ...[
          const SizedBox(height: 12),
          _buildLessonSelector(),
        ],
      ],
    );
  }

  Widget _buildLessonSelector() {
    final module = widget.course.modules?.firstWhere(
      (m) => m.moduleId == _selectedModuleId,
      orElse: () => CourseModule(title: ''),
    );
    final lessons = module?.lessons ?? [];

    return DropdownButtonFormField<String?>(
      key: const Key('scopeLesson'),
      decoration: InputDecoration(
        labelText: 'Lesson (optional)',
        hintText: 'All lessons in module',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.play_lesson),
      ),
      initialValue: _selectedLessonId,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All lessons in module'),
        ),
        ...lessons.map((l) => DropdownMenuItem(
              value: l.lessonId,
              child: Text(l.title),
            )),
      ],
      onChanged: (value) => setState(() => _selectedLessonId = value),
    );
  }

  Widget _buildPlatformSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Platform',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose where you want to publish this content',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MediaPlatform.values.map((platform) {
            final isSelected = _selectedPlatform == platform;
            return FilterChip(
              key: Key('platform_${platform.name}'),
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPlatformIcon(platform),
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(_getPlatformLabel(platform)),
                ],
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              onSelected: (selected) {
                setState(() {
                  _selectedPlatform = selected ? platform : null;
                  _selectedMediaType = null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMediaTypeSelector() {
    final availableTypes = _platformMediaTypes[_selectedPlatform] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the type of content to generate for ${_getPlatformLabel(_selectedPlatform!)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTypes.map((mediaType) {
            final isSelected = _selectedMediaType == mediaType;
            return ChoiceChip(
              key: Key('mediaType_${mediaType.name}'),
              selected: isSelected,
              label: Text(_getMediaTypeLabel(mediaType)),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              onSelected: (selected) {
                setState(() {
                  _selectedMediaType = selected ? mediaType : null;
                });
              },
            );
          }).toList(),
        ),
        if (_selectedMediaType != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMediaTypeDescription(_selectedMediaType!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGeneratedContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Content Generated Successfully!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _generatedContent!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canGenerate = _selectedPlatform != null && _selectedMediaType != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            key: const Key('generateMediaButton'),
            onPressed: canGenerate && !_isGenerating ? _generateMedia : null,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGenerating ? 'Generating...' : 'Generate Content'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _generateMedia() {
    setState(() {
      _isGenerating = true;
      _generatedContent = null;
      _errorMessage = null;
    });

    context.read<CourseBloc>().add(
          CourseMediaGenerate(
            courseId: widget.course.courseId!,
            platform: _selectedPlatform!,
            mediaType: _selectedMediaType!,
            moduleId: _selectedModuleId,
            lessonId: _selectedLessonId,
          ),
        );
  }

  IconData _getPlatformIcon(MediaPlatform platform) {
    switch (platform) {
      case MediaPlatform.linkedin:
        return Icons.work;
      case MediaPlatform.medium:
        return Icons.article;
      case MediaPlatform.email:
        return Icons.email;
      case MediaPlatform.youtube:
        return Icons.play_circle_filled;
      case MediaPlatform.twitter:
        return Icons.alternate_email;
      case MediaPlatform.substack:
        return Icons.newspaper;
      case MediaPlatform.inapp:
        return Icons.phone_android;
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
        return 'In-App';
    }
  }

  String _getMediaTypeLabel(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.post:
        return 'Post';
      case MediaType.article:
        return 'Article';
      case MediaType.sequence:
        return 'Email Sequence';
      case MediaType.script:
        return 'Video Script';
      case MediaType.thread:
        return 'Thread';
      case MediaType.tutorial:
        return 'Tutorial';
    }
  }

  String _getMediaTypeDescription(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.post:
        return 'A short-form social media post optimized for engagement.';
      case MediaType.article:
        return 'A long-form article with in-depth content suitable for blogging platforms.';
      case MediaType.sequence:
        return 'A series of emails designed to educate and engage over time.';
      case MediaType.script:
        return 'A video script with intro, main content, and call-to-action.';
      case MediaType.thread:
        return 'A series of connected posts for storytelling or explanations.';
      case MediaType.tutorial:
        return 'Step-by-step instructional content with clear guidance.';
    }
  }
}
