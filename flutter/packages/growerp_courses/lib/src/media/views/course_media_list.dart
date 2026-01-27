/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_media_bloc.dart';
import 'media_preview.dart';

/// List of generated course media
class CourseMediaList extends StatelessWidget {
  final String? courseId;

  const CourseMediaList({super.key, this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CourseMediaBloc(restClient: context.read<RestClient>())
            ..add(MediaFetch(courseId: courseId)),
      child: CourseMediaListView(courseId: courseId),
    );
  }
}

class CourseMediaListView extends StatelessWidget {
  final String? courseId;

  const CourseMediaListView({super.key, this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseMediaBloc, CourseMediaState>(
      listener: (context, state) {
        if (state.status == MediaBlocStatus.failure && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == MediaBlocStatus.loading ||
            state.status == MediaBlocStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.mediaList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No generated content',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Generate content from your courses'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<CourseMediaBloc>().add(MediaFetch(courseId: courseId));
          },
          child: ListView.builder(
            itemCount: state.mediaList.length,
            itemBuilder: (context, index) {
              return _buildMediaCard(context, state.mediaList[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildMediaCard(BuildContext context, CourseMedia media) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPlatformColor(media.platform),
          child: Icon(_getPlatformIcon(media.platform), color: Colors.white),
        ),
        title: Text(
          media.title ?? '${_getPlatformLabel(media.platform)} Content',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              media.displayContent.length > 100
                  ? '${media.displayContent.substring(0, 100)}...'
                  : media.displayContent,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(media.status),
                const SizedBox(width: 8),
                if (media.createdDate != null)
                  Text(
                    _formatDate(media.createdDate!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) => MediaPreview(media: media),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(MediaStatus? status) {
    Color color;
    String label;
    switch (status) {
      case MediaStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case MediaStatus.reviewed:
        color = Colors.blue;
        label = 'Reviewed';
        break;
      case MediaStatus.scheduled:
        color = Colors.orange;
        label = 'Scheduled';
        break;
      case MediaStatus.published:
        color = Colors.green;
        label = 'Published';
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

  Color _getPlatformColor(MediaPlatform? platform) {
    switch (platform) {
      case MediaPlatform.linkedin:
        return const Color(0xFF0A66C2);
      case MediaPlatform.medium:
        return Colors.black;
      case MediaPlatform.email:
        return Colors.blue;
      case MediaPlatform.youtube:
        return Colors.red;
      case MediaPlatform.twitter:
        return Colors.black;
      case MediaPlatform.substack:
        return Colors.orange;
      case MediaPlatform.inapp:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPlatformIcon(MediaPlatform? platform) {
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
      default:
        return Icons.content_copy;
    }
  }

  String _getPlatformLabel(MediaPlatform? platform) {
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
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
