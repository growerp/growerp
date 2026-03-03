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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../domains/domains.dart';

/// Premium navigation rail with gradient background, animated selections,
/// and glassmorphism styling for a modern, sophisticated look.
Widget myNavigationRail(
  BuildContext context,
  Widget child,
  int menuIndex,
  List<MenuItem> menu,
) {
  final localizations = CoreLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;

  if (menu.isEmpty) {
    return FatalErrorForm(message: localizations.noAccessHere);
  }

  return Row(
    children: <Widget>[
      // Premium navigation rail with gradient
      Container(
        width: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.9),
              colorScheme.secondaryContainer.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraint) {
            final screenHeight = MediaQuery.of(context).size.height;
            final isSmallTablet = screenHeight < 700;

            return SizedBox(
              height: constraint.maxHeight,
              child: Column(
                children: [
                  // Premium user profile card (fixed at top)
                  SizedBox(
                    height: isSmallTablet
                        ? 8
                        : (ResponsiveBreakpoints.of(context).isTablet
                              ? 25
                              : 12),
                  ),
                  _buildUserProfileCard(context, auth, colorScheme, isDark),
                  SizedBox(height: isSmallTablet ? 8 : 16),
                  Divider(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    indent: 16,
                    endIndent: 16,
                  ),
                  SizedBox(height: isSmallTablet ? 4 : 8),
                  // Scrollable destinations + pinned theme button at bottom.
                  // Using a custom Column+SingleChildScrollView avoids the
                  // NavigationRail internal RenderFlex overflow that occurs
                  // when there are more items than fit the available height.
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            key: const Key('navigationrail'),
                            child: Column(
                              children: List.generate(menu.length, (index) {
                                return _buildNavDestination(
                                  context,
                                  menu[index],
                                  index == menuIndex,
                                  colorScheme,
                                  localizations,
                                );
                              }),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: isSmallTablet ? 8 : 16,
                          ),
                          child: _buildThemeButton(
                            context,
                            localizations,
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // Main content area
      Expanded(child: child),
    ],
  );
}

/// Builds a single scrollable nav destination that mimics NavigationRail
/// appearance with animated selection indicator.
Widget _buildNavDestination(
  BuildContext context,
  MenuItem option,
  bool isSelected,
  ColorScheme colorScheme,
  CoreLocalizations localizations,
) {
  Widget iconWidget;
  Widget selectedIconWidget;

  if (option.iconName != null) {
    iconWidget = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child:
          getIconFromRegistry(option.iconName) ??
          const Icon(Icons.circle, size: 28, key: Key('defaultIcon')),
    );
    selectedIconWidget = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: RadialGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.2),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: IconTheme(
        data: IconThemeData(color: colorScheme.primary, size: 28),
        child:
            getIconFromRegistry(option.iconName) ??
            const Icon(Icons.circle, size: 28),
      ),
    );
  } else if (option.image != null) {
    iconWidget = Image.asset(
      option.image!,
      width: 40,
      height: 40,
      key: Key('icon_${option.menuItemId}'),
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.circle, size: 40),
    );
    selectedIconWidget = option.selectedImage != null
        ? Image.asset(
            option.selectedImage!,
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.circle, size: 40),
          )
        : iconWidget;
  } else {
    iconWidget = const Icon(Icons.circle, size: 40, key: Key('defaultIcon'));
    selectedIconWidget = const Icon(Icons.circle, size: 40);
  }

  return InkWell(
    key: Key('tap${option.route}'),
    onTap: () {
      if (option.route != null) context.go(option.route!);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.primary.withValues(alpha: 0.15),
                  )
                : null,
            child: isSelected ? selectedIconWidget : iconWidget,
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 80,
            child: Text(
              HelperFunctions.translateMenuTitle(localizations, option.title),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds a premium user profile card with avatar ring and gradient background.
/// Adapts to available space - shows compact version on smaller tablets.
Widget _buildUserProfileCard(
  BuildContext context,
  Authenticate? auth,
  ColorScheme colorScheme,
  bool isDark,
) {
  // Check if we're on a smaller tablet (7-inch or similar) using screen height
  final screenHeight = MediaQuery.of(context).size.height;
  final isSmallTablet = screenHeight < 700;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      key: const Key('tapUser'),
      onTap: () => context.push('/user', extra: auth?.user),
      borderRadius: BorderRadius.circular(isSmallTablet ? 12 : 16),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isSmallTablet ? 4 : 8),
        padding: EdgeInsets.all(isSmallTablet ? 6 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallTablet ? 12 : 16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withValues(alpha: isDark ? 0.3 : 0.5),
              colorScheme.surface.withValues(alpha: isDark ? 0.2 : 0.3),
            ],
          ),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: isSmallTablet
            ? // Compact horizontal layout for small tablets
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smaller avatar
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.surface,
                      child: auth?.user?.image != null
                          ? ClipOval(
                              child: Image.memory(
                                auth!.user!.image!,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              auth?.user?.firstName?.substring(0, 1) ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // User name in column
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth?.user?.firstName ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          auth?.user?.lastName ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : // Standard vertical layout for larger screens
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar with gradient ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.surface,
                      child: auth?.user?.image != null
                          ? ClipOval(
                              child: Image.memory(
                                auth!.user!.image!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              auth?.user?.firstName?.substring(0, 1) ?? '',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // User name
                  Text(
                    auth?.user?.firstName ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    auth?.user?.lastName ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    ),
  );
}

/// Builds the theme picker button with icon and gradient background on hover.
/// Adapts to available space on smaller tablets.
Widget _buildThemeButton(
  BuildContext context,
  CoreLocalizations localizations,
  ColorScheme colorScheme,
) {
  // Check if we're on a smaller tablet (7-inch or similar)
  final screenHeight = MediaQuery.of(context).size.height;
  final isSmallTablet = screenHeight < 700;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      key: const Key('theme'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const ThemePickerDialog(),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallTablet ? 6 : 12,
          horizontal: isSmallTablet ? 8 : 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallTablet ? 6 : 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.tertiary.withValues(alpha: 0.2),
                    colorScheme.tertiary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.palette,
                size: isSmallTablet ? 20 : 24,
                color: colorScheme.tertiary,
              ),
            ),
            if (!isSmallTablet) ...[
              const SizedBox(height: 4),
              Text(
                localizations.theme,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
