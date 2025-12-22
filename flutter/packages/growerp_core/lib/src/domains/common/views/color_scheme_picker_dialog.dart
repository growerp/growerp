/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';
import '../bloc/theme_bloc.dart';

/// A curated list of FlexScheme options for user selection.
/// These are chosen for their professional appearance and variety.
const List<FlexScheme> curatedSchemes = [
  FlexScheme.jungle, // Default GrowERP - green/teal
  FlexScheme.blueM3, // Material 3 blue
  FlexScheme.indigoM3, // Material 3 indigo
  FlexScheme.purpleM3, // Material 3 purple
  FlexScheme.pinkM3, // Material 3 pink
  FlexScheme.redM3, // Material 3 red
  FlexScheme.orangeM3, // Material 3 orange
  FlexScheme.aquaBlue, // Aqua/Blue tones
  FlexScheme.espresso, // Brown/warm tones
  FlexScheme.hippieBlue, // Retro blue palette
  FlexScheme.money, // Green money theme
  FlexScheme.wasabi, // Yellow-green
];

/// Premium theme picker dialog with gradient header, animated mode toggle,
/// and polished color scheme tiles.
class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final themeBloc = context.read<ThemeBloc>();
          final currentScheme = themeState.colorScheme;
          final isDark = themeState.themeMode == ThemeMode.dark;

          return Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium gradient header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface.withValues(alpha: 0.5),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.theme,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Customize your experience',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Premium Light/Dark Mode Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surface,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModeButton(
                            context: context,
                            icon: Icons.light_mode,
                            label: 'Light',
                            isSelected: !isDark,
                            colorScheme: colorScheme,
                            onTap: () {
                              if (isDark) themeBloc.add(ThemeSwitch());
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildModeButton(
                            context: context,
                            icon: Icons.dark_mode,
                            label: 'Dark',
                            isSelected: isDark,
                            colorScheme: colorScheme,
                            onTap: () {
                              if (!isDark) themeBloc.add(ThemeSwitch());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Color Scheme Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.color_lens,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.colorScheme,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Color Scheme Grid
                Flexible(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: curatedSchemes.length,
                    itemBuilder: (context, index) {
                      final scheme = curatedSchemes[index];
                      final isSelected = scheme == currentScheme;
                      final colors = isDark
                          ? FlexThemeData.dark(scheme: scheme).colorScheme
                          : FlexThemeData.light(scheme: scheme).colorScheme;

                      return _ColorSchemeTile(
                        scheme: scheme,
                        colors: colors,
                        isSelected: isSelected,
                        onTap: () {
                          themeBloc.add(ColorSchemeChange(scheme));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: label == 'Dark' ? const Key('themeSwitch') : null,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy alias for backward compatibility
@Deprecated('Use ThemePickerDialog instead')
typedef ColorSchemePickerDialog = ThemePickerDialog;

class _ColorSchemeTile extends StatefulWidget {
  const _ColorSchemeTile({
    required this.scheme,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  final FlexScheme scheme;
  final ColorScheme colors;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ColorSchemeTile> createState() => _ColorSchemeTileState();
}

class _ColorSchemeTileState extends State<_ColorSchemeTile> {
  bool _isHovered = false;

  String _formatSchemeName(FlexScheme scheme) {
    final name = scheme.name;
    final formatted = name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _formatSchemeName(widget.scheme),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          key: Key('scheme_${widget.scheme.name}'),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.diagonal3Values(
              _isHovered && !widget.isSelected ? 1.05 : 1.0,
              _isHovered && !widget.isSelected ? 1.05 : 1.0,
              1.0,
            ),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? widget.colors.primary
                    : widget.colors.outline.withValues(alpha: 0.3),
                width: widget.isSelected ? 3 : 1.5,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.colors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : _isHovered
                  ? [
                      BoxShadow(
                        color: widget.colors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Primary color row
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(color: widget.colors.primary),
                            ),
                            Expanded(
                              child: Container(color: widget.colors.secondary),
                            ),
                          ],
                        ),
                      ),
                      // Tertiary and surface row
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(color: widget.colors.tertiary),
                            ),
                            Expanded(
                              child: Container(
                                color: widget.colors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Selection checkmark
                  if (widget.isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.colors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: widget.colors.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
