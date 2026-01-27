/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Position for help overlay
enum TooltipPosition { topLeft, topRight, bottomLeft, bottomRight, center }

/// Help overlay widget for contextual help in the application
class HelpOverlay extends StatelessWidget {
  final String? courseId;
  final String? lessonId;
  final String? title;
  final String? content;
  final Widget child;
  final TooltipPosition position;
  final bool showHelpButton;

  const HelpOverlay({
    super.key,
    this.courseId,
    this.lessonId,
    this.title,
    this.content,
    required this.child,
    this.position = TooltipPosition.bottomRight,
    this.showHelpButton = true,
  });

  /// Show a help overlay on a specific screen
  static void show(
    BuildContext context, {
    String? courseId,
    String? lessonId,
    String? content,
    TooltipPosition position = TooltipPosition.bottomRight,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => HelpOverlayDialog(
        courseId: courseId,
        lessonId: lessonId,
        content: content,
        position: position,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showHelpButton) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'help_$courseId',
            onPressed: () => show(
              context,
              courseId: courseId,
              lessonId: lessonId,
              content: content,
            ),
            child: const Icon(Icons.help_outline),
          ),
        ),
      ],
    );
  }
}

/// Dialog shown when help is requested
class HelpOverlayDialog extends StatefulWidget {
  final String? courseId;
  final String? lessonId;
  final String? content;
  final TooltipPosition position;

  const HelpOverlayDialog({
    super.key,
    this.courseId,
    this.lessonId,
    this.content,
    this.position = TooltipPosition.bottomRight,
  });

  @override
  State<HelpOverlayDialog> createState() => _HelpOverlayDialogState();
}

class _HelpOverlayDialogState extends State<HelpOverlayDialog> {
  bool _isLoading = false;
  String? _helpContent;
  String? _helpTitle;

  @override
  void initState() {
    super.initState();
    _loadHelp();
  }

  Future<void> _loadHelp() async {
    if (widget.content != null) {
      setState(() {
        _helpContent = widget.content;
        _helpTitle = 'Help';
      });
      return;
    }

    if (widget.courseId != null || widget.lessonId != null) {
      setState(() => _isLoading = true);
      // TODO: Load help content from course/lesson via API
      // For now, show placeholder
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _isLoading = false;
        _helpTitle = 'How to use this screen';
        _helpContent = '''
# Getting Started

This is contextual help for the current screen.

## Quick Tips

- Click items to select them
- Use the **+** button to add new entries
- Right-click for more options

## Related Lessons

If you want to learn more, check out the GrowERP training course.
''';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alignment = _getAlignment();

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          top: alignment.top,
          bottom: alignment.bottom,
          left: alignment.left,
          right: alignment.right,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 350,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  const Divider(height: 1),
                  Flexible(child: _buildContent()),
                  if (widget.courseId != null || widget.lessonId != null)
                    _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _helpTitle ?? 'Help',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_helpContent == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No help content available for this screen.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(data: _helpContent!, selectable: true),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.school),
            label: const Text('View Full Course'),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to full course viewer
            },
          ),
        ],
      ),
    );
  }

  _Alignment _getAlignment() {
    switch (widget.position) {
      case TooltipPosition.topLeft:
        return _Alignment(top: 80, left: 16);
      case TooltipPosition.topRight:
        return _Alignment(top: 80, right: 16);
      case TooltipPosition.bottomLeft:
        return _Alignment(bottom: 80, left: 16);
      case TooltipPosition.bottomRight:
        return _Alignment(bottom: 80, right: 16);
      case TooltipPosition.center:
        return _Alignment(top: 100, left: 16, right: 16);
    }
  }
}

class _Alignment {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  _Alignment({this.top, this.bottom, this.left, this.right});
}
