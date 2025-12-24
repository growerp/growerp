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
  List<NavigationRailDestination> items = [];
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;

  for (var option in menu) {
    // Try iconName first, then fall back to image paths (for top-level items)
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
      // Use image assets for top-level menu items
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

    items.add(
      NavigationRailDestination(
        icon: Container(key: Key('tap${option.route}'), child: iconWidget),
        selectedIcon: selectedIconWidget,
        label: SizedBox(
          width: 80,
          child: Text(
            HelperFunctions.translateMenuTitle(localizations, option.title),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  if (items.isEmpty) {
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
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Premium user profile card
                      SizedBox(
                        height: ResponsiveBreakpoints.of(context).isTablet
                            ? 25
                            : 12,
                      ),
                      _buildUserProfileCard(context, auth, colorScheme, isDark),
                      const SizedBox(height: 16),
                      Divider(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        indent: 16,
                        endIndent: 16,
                      ),
                      const SizedBox(height: 8),
                      // Navigation items
                      Expanded(
                        child: NavigationRail(
                          backgroundColor: Colors.transparent,
                          key: const Key('navigationrail'),
                          selectedIndex: menuIndex,
                          onDestinationSelected: (int index) {
                            if (index < menu.length &&
                                menu[index].route != null) {
                              context.go(menu[index].route!);
                            }
                          },
                          labelType: NavigationRailLabelType.all,
                          destinations: items,
                          groupAlignment: -1.0,
                          indicatorColor: colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          indicatorShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          useIndicator: true,
                        ),
                      ),
                      // Theme picker at bottom
                      _buildThemeButton(context, localizations, colorScheme),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
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

/// Builds a premium user profile card with avatar ring and gradient background
Widget _buildUserProfileCard(
  BuildContext context,
  Authenticate? auth,
  ColorScheme colorScheme,
  bool isDark,
) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      key: const Key('tapUser'),
      onTap: () => context.go('/user', extra: auth?.user),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
        child: Column(
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

/// Builds the theme picker button with icon and gradient background on hover
Widget _buildThemeButton(
  BuildContext context,
  CoreLocalizations localizations,
  ColorScheme colorScheme,
) {
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.tertiary.withValues(alpha: 0.2),
                    colorScheme.tertiary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(Icons.palette, size: 24, color: colorScheme.tertiary),
            ),
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
        ),
      ),
    ),
  );
}
