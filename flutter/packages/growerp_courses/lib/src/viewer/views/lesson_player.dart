/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:growerp_models/growerp_models.dart';

/// Individual lesson player widget
class LessonPlayer extends StatelessWidget {
  final CourseLesson lesson;
  final bool isCompleted;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const LessonPlayer({
    super.key,
    required this.lesson,
    this.isCompleted = false,
    this.onMarkComplete,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          if (lesson.imageUrl != null) _buildImage(),
          if (lesson.videoUrl != null) _buildVideoPlaceholder(),
          if (lesson.content != null && lesson.content!.isNotEmpty)
            MarkdownBody(data: lesson.content!, selectable: true),
          if (lesson.keyPoints != null && lesson.keyPoints!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildKeyPoints(context),
          ],
          const SizedBox(height: 32),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lesson.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            if (lesson.estimatedDuration != null) ...[
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 4),
              Text('${lesson.estimatedDuration} min'),
              const SizedBox(width: 16),
            ],
            if (isCompleted) ...[
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              const Text('Completed', style: TextStyle(color: Colors.green)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          lesson.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image, size: 48)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.play_circle_outline,
                size: 64,
                color: Colors.white,
              ),
              onPressed: () {
                // TODO: Implement video player or launch URL
              },
            ),
            const Text('Video content', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPoints(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Key Points',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            ...lesson.keyPoints!.map(
              (point) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(point)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onPrevious != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            onPressed: onPrevious,
          )
        else
          const SizedBox(width: 100),
        if (onMarkComplete != null && !isCompleted)
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Complete'),
            onPressed: onMarkComplete,
          ),
        if (isCompleted)
          const Chip(
            avatar: Icon(Icons.check, color: Colors.white),
            label: Text('Completed'),
            backgroundColor: Colors.green,
            labelStyle: TextStyle(color: Colors.white),
          ),
        if (onNext != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            onPressed: onNext,
          )
        else
          const SizedBox(width: 100),
      ],
    );
  }
}
