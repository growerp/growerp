// Enhanced table styling following Stitch Orders Management design
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// Padding for table rows and columns - more spacious for better readability
var companyUserPadding = const SpanPadding(trailing: 8, leading: 12);

/// Get background decoration for table rows following Stitch design
/// - Header row: Bold colored background
/// - Data rows: Alternating backgrounds for better readability
SpanDecoration? getCompanyUserBackGround(BuildContext context, int index) {
  final colorScheme = Theme.of(context).colorScheme;

  // Header row - styled with primary color tint
  if (index == 0) {
    return SpanDecoration(
      color: colorScheme.surfaceContainerHighest,
      border: SpanBorder(
        trailing: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        leading: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // Alternating row colors for data rows
  if (index.isOdd) {
    return SpanDecoration(
      color: colorScheme.surfaceContainerLowest,
      border: SpanBorder(
        trailing: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
    );
  } else {
    return SpanDecoration(
      color: colorScheme.surface,
      border: SpanBorder(
        trailing: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

/// Enhanced table header text style
TextStyle getTableHeaderStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: colorScheme.onSurfaceVariant,
    letterSpacing: 0.5,
  );
}

/// Table data cell text style
TextStyle getTableCellStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: colorScheme.onSurface,
  );
}
