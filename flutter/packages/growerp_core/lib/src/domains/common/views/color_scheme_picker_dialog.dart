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

/// Dialog for selecting theme mode and color scheme.
/// Shows a light/dark toggle and a grid of color swatches.
class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;

    return Dialog(
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final themeBloc = context.read<ThemeBloc>();
          final currentScheme = themeState.colorScheme;
          final isDark = themeState.themeMode == ThemeMode.dark;

          return Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.palette),
                      const SizedBox(width: 8),
                      Text(
                        localizations.theme,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Light/Dark Mode Toggle
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.light_mode,
                        color: !isDark
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        key: const Key('themeSwitch'),
                        value: isDark,
                        onChanged: (value) {
                          themeBloc.add(ThemeSwitch());
                        },
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.dark_mode,
                        color: isDark
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ],
                  ),
                ),

                // Color Scheme Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      localizations.colorScheme,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Color Scheme Grid
                Flexible(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
}

/// Legacy alias for backward compatibility
@Deprecated('Use ThemePickerDialog instead')
typedef ColorSchemePickerDialog = ThemePickerDialog;

class _ColorSchemeTile extends StatelessWidget {
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

  String _formatSchemeName(FlexScheme scheme) {
    // Convert enum name to human-readable format
    final name = scheme.name;
    // Insert space before capital letters and capitalize first letter
    final formatted = name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _formatSchemeName(scheme),
      child: InkWell(
        key: Key('scheme_${scheme.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outline,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: [
                // Primary color row
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Container(color: colors.primary)),
                      Expanded(child: Container(color: colors.secondary)),
                    ],
                  ),
                ),
                // Tertiary and surface row
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: Container(color: colors.tertiary)),
                      Expanded(child: Container(color: colors.surface)),
                    ],
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
