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

/// A filter bar widget for list views following the Stitch design pattern.
///
/// Features:
/// - Search text field
/// - Optional dropdown filters
/// - Responsive layout (stacks on mobile)
///
/// Usage:
/// ```dart
/// ListFilterBar(
///   searchHint: 'Search users...',
///   onSearchChanged: (value) => bloc.add(UserSearch(value)),
///   filters: [
///     FilterDropdown(
///       label: 'Role',
///       value: selectedRole,
///       items: roles,
///       onChanged: (value) => setState(() => selectedRole = value),
///     ),
///   ],
/// )
/// ```
class ListFilterBar extends StatelessWidget {
  /// Hint text for the search field
  final String searchHint;

  /// Callback when search text changes
  final ValueChanged<String>? onSearchChanged;

  /// Initial search value
  final String? searchValue;

  /// Controller for the search field
  final TextEditingController? searchController;

  /// List of filter dropdown widgets
  final List<Widget>? filters;

  /// Optional trailing actions (like bulk action buttons)
  final List<Widget>? actions;

  /// Whether to show the search field
  final bool showSearch;

  /// Optional focus node for the search field
  final FocusNode? focusNode;

  const ListFilterBar({
    super.key,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.searchValue,
    this.searchController,
    this.filters,
    this.actions,
    this.showSearch = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: isPhone
          ? _buildMobileLayout(context, colorScheme)
          : _buildDesktopLayout(context, colorScheme),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        if (showSearch) ...[
          Expanded(flex: 2, child: _buildSearchField(colorScheme)),
          const SizedBox(width: 16),
        ],
        if (filters != null) ...[
          ...filters!.map(
            (filter) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: filter,
            ),
          ),
        ],
        const Spacer(),
        if (actions != null) ...actions!,
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSearch) _buildSearchField(colorScheme),
        if (filters != null && filters!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters!
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: filter,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
        ],
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return _SearchField(
      searchHint: searchHint,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      colorScheme: colorScheme,
      focusNode: focusNode,
    );
  }
}

class _SearchField extends StatefulWidget {
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ColorScheme colorScheme;
  final FocusNode? focusNode;

  const _SearchField({
    required this.searchHint,
    required this.colorScheme,
    this.searchController,
    this.onSearchChanged,
    this.focusNode,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.searchController ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    // Only dispose if we created it internally
    if (widget.searchController == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    return GestureDetector(
      key: const Key('search'),
      child: TextField(
        key: const Key('searchField'),
        controller: _controller,
        focusNode: widget.focusNode,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  key: const Key('clearSearch'),
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged?.call('');
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          isDense: true,
        ),
        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      ),
    );
  }
}

/// A dropdown filter widget for use with ListFilterBar
class FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double? width;

  const FilterDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width ?? 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          dropdownColor: colorScheme.surface,
        ),
      ),
    );
  }
}

/// A styled table header row following the Stitch design pattern
class StyledTableHeader extends StatelessWidget {
  final List<String> columns;
  final List<double> columnWidths;
  final VoidCallback? onSelectAll;
  final bool showCheckbox;
  final bool? isAllSelected;

  const StyledTableHeader({
    super.key,
    required this.columns,
    required this.columnWidths,
    this.onSelectAll,
    this.showCheckbox = false,
    this.isAllSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (showCheckbox) ...[
            Checkbox(
              value: isAllSelected ?? false,
              onChanged: (_) => onSelectAll?.call(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
          ],
          ...List.generate(columns.length, (index) {
            return SizedBox(
              width: columnWidths[index],
              child: Text(
                columns[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
