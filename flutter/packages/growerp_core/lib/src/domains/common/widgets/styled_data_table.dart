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

/// A styled data table following the Stitch Orders Management design pattern.
///
/// Features:
/// - Styled header row with bold text
/// - Alternating row colors
/// - Hover effects on rows
/// - Better spacing and padding
/// - Support for custom cell widgets
class StyledDataTable extends StatelessWidget {
  /// Column definitions with header text and flex values
  final List<StyledColumn> columns;

  /// Row data as list of cell widgets
  final List<List<Widget>> rows;

  /// Callback when a row is tapped
  final void Function(int index)? onRowTap;

  /// Height of each data row
  final double rowHeight;

  /// Optional scroll controller
  final ScrollController? scrollController;

  /// Whether to show loading skeleton
  final bool isLoading;

  /// Number of skeleton rows to show when loading
  final int skeletonRowCount;

  const StyledDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.rowHeight = 56,
    this.scrollController,
    this.isLoading = false,
    this.skeletonRowCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return _buildSkeletonTable(context, colorScheme);
    }

    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No data found',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header row
        _buildHeaderRow(context, colorScheme),
        // Data rows
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: rows.length,
            itemBuilder: (context, index) =>
                _buildDataRow(context, colorScheme, index),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          return Expanded(
            flex: column.flex,
            child: Text(
              column.header,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
              textAlign: column.alignment,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    ColorScheme colorScheme,
    int index,
  ) {
    final isEven = index.isEven;
    final rowData = rows[index];

    return Material(
      color: isEven ? colorScheme.surface : colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onRowTap != null ? () => onRowTap!(index) : null,
        hoverColor: colorScheme.primary.withValues(alpha: 0.08),
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        child: Container(
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: List.generate(columns.length, (colIndex) {
              return Expanded(
                flex: columns[colIndex].flex,
                child: Align(
                  alignment: _getAlignment(columns[colIndex].alignment),
                  child: colIndex < rowData.length
                      ? rowData[colIndex]
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.center:
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }

  Widget _buildSkeletonTable(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // Skeleton header
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          child: Row(
            children: columns.map((column) {
              return Expanded(
                flex: column.flex,
                child: Container(
                  height: 12,
                  margin: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Skeleton rows
        Expanded(
          child: ListView.builder(
            itemCount: skeletonRowCount,
            itemBuilder: (context, index) {
              final isEven = index.isEven;
              return Container(
                height: rowHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: isEven
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerLowest,
                child: Row(
                  children: columns.map((column) {
                    return Expanded(flex: column.flex, child: _SkeletonCell());
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Column definition for StyledDataTable
class StyledColumn {
  final String header;
  final int flex;
  final TextAlign alignment;

  const StyledColumn({
    required this.header,
    this.flex = 1,
    this.alignment = TextAlign.left,
  });
}

/// Animated skeleton cell for loading state
class _SkeletonCell extends StatefulWidget {
  @override
  State<_SkeletonCell> createState() => _SkeletonCellState();
}

class _SkeletonCellState extends State<_SkeletonCell>
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
      begin: 0.3,
      end: 0.7,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 16,
          margin: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(
              alpha: _animation.value * 0.3,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
