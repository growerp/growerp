/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';

/// A skeleton loading placeholder widget with shimmer animation.
///
/// Use this widget to indicate loading states for content that is being fetched.
/// The shimmer effect provides visual feedback that content is loading.
///
/// Usage:
/// ```dart
/// // Basic rectangle skeleton
/// SkeletonLoader(
///   width: 200,
///   height: 20,
/// )
///
/// // Circular skeleton (for avatars)
/// SkeletonLoader.circle(size: 48)
///
/// // Card skeleton
/// SkeletonLoader.card(height: 120)
/// ```
class SkeletonLoader extends StatefulWidget {
  /// Width of the skeleton. Use double.infinity for full width.
  final double? width;

  /// Height of the skeleton
  final double height;

  /// Border radius of the skeleton
  final BorderRadius borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// Creates a circular skeleton, useful for avatar placeholders
  const SkeletonLoader.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = const BorderRadius.all(Radius.circular(1000));

  /// Creates a text line skeleton
  factory SkeletonLoader.text({Key? key, double? width, double height = 14}) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    );
  }

  /// Creates a card skeleton with standard padding and radius
  factory SkeletonLoader.card({Key? key, double? width, double height = 100}) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final highlightColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton layout for list items with avatar, title, and subtitle
class SkeletonListItem extends StatelessWidget {
  /// Whether to show an avatar placeholder
  final bool showAvatar;

  /// Number of text lines to show
  final int lines;

  /// Height of each text line
  final double lineHeight;

  /// Spacing between lines
  final double lineSpacing;

  const SkeletonListItem({
    super.key,
    this.showAvatar = true,
    this.lines = 2,
    this.lineHeight = 14,
    this.lineSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showAvatar) ...[
            const SkeletonLoader.circle(size: 48),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines, (index) {
                // Make subsequent lines shorter for visual variety
                final widthFactor = index == 0
                    ? 0.8
                    : 0.5 + (0.3 / (index + 1));
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < lines - 1 ? lineSpacing : 0,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor,
                    child: SkeletonLoader.text(height: lineHeight),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton layout for dashboard cards
class SkeletonDashboardCard extends StatelessWidget {
  const SkeletonDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SkeletonLoader.circle(size: 48),
          const SizedBox(height: 12),
          SkeletonLoader.text(width: 80, height: 16),
          const SizedBox(height: 8),
          SkeletonLoader.text(width: 60, height: 12),
        ],
      ),
    );
  }
}

/// A skeleton layout for data tables
class SkeletonTable extends StatelessWidget {
  /// Number of rows to display
  final int rowCount;

  /// Number of columns
  final int columnCount;

  /// Height of each row
  final double rowHeight;

  const SkeletonTable({
    super.key,
    this.rowCount = 5,
    this.columnCount = 4,
    this.rowHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Container(
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: List.generate(
              columnCount,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SkeletonLoader.text(height: 14),
                ),
              ),
            ),
          ),
        ),
        // Data rows
        ...List.generate(
          rowCount,
          (rowIndex) => Container(
            height: rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: List.generate(
                columnCount,
                (colIndex) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SkeletonLoader.text(
                      height: 12,
                      width: colIndex == 0 ? null : 60,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
