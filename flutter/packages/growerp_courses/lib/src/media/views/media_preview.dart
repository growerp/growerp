/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:growerp_models/growerp_models.dart';

/// Preview dialog for generated media content
class MediaPreview extends StatefulWidget {
  final CourseMedia media;

  const MediaPreview({super.key, required this.media});

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  late TextEditingController _contentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.media.editedContent ?? widget.media.generatedContent ?? '',
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 700,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.media.title ?? 'Media Preview'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
                tooltip: _isEditing ? 'Preview' : 'Edit',
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy to clipboard',
                onPressed: _copyToClipboard,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1),
              Expanded(child: _isEditing ? _buildEditor() : _buildPreview()),
            ],
          ),
          bottomNavigationBar: _buildActionButtons(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: Row(
        children: [
          _buildPlatformChip(),
          const SizedBox(width: 16),
          _buildStatusChip(),
          const Spacer(),
          if (widget.media.createdDate != null)
            Text(
              'Generated: ${_formatDate(widget.media.createdDate!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip() {
    return Chip(
      avatar: Icon(_getPlatformIcon(widget.media.platform), size: 18),
      label: Text(_getPlatformLabel(widget.media.platform)),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;
    switch (widget.media.status) {
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
    return Chip(
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }

  Widget _buildPreview() {
    final content = _contentController.text;

    if (content.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(data: content, selectable: true),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Edit content here...',
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate'),
            onPressed: () {
              // TODO: Implement regeneration
              Navigator.pop(context, 'regenerate');
            },
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _contentController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveChanges() {
    final updatedMedia = widget.media.copyWith(
      editedContent: _contentController.text,
    );
    Navigator.pop(context, updatedMedia);
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
