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
import '../domains/domains.dart';

/// Premium drawer widget with gradient styling, enhanced user profile,
/// and polished menu items for a modern mobile experience.
Widget? myDrawer(BuildContext context, bool isPhone, List<MenuItem> menu) {
  final localizations = CoreLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;

  // Add theme option to menu (combines light/dark + color scheme)
  List<MenuItem> options = List.from(menu);
  options.add(
    MenuItem(
      menuItemId: 'theme',
      menuConfigurationId: 'system',
      title: localizations.theme,
      route: 'theme',
      iconName: 'palette',
      sequenceNum: 999,
      isActive: true,
    ),
  );

  bool loggedIn = auth?.apiKey != null;

  if (loggedIn && isPhone) {
    return Drawer(
      width: 260,
      key: const Key('drawer'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: ListView.builder(
          key: const Key('listView'),
          itemCount: options.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              // Premium drawer header with gradient
              return Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  key: const Key('tapUser'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/user', extra: auth?.user);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Avatar with gradient ring
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: colorScheme.surface,
                          child: auth?.user?.image != null
                              ? ClipOval(
                                  child: Image.memory(
                                    auth!.user!.image!,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  auth?.user?.firstName?.substring(0, 1) ?? '',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User name with premium styling
                      Text(
                        "${auth?.user!.firstName ?? ''} ${auth?.user!.lastName ?? ''}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (auth?.user?.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          auth!.user!.email!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            final menuOption = options[i - 1];

            if (menuOption.route == "theme") {
              return _buildDrawerItem(
                context: context,
                colorScheme: colorScheme,
                icon: Icons.palette,
                iconColor: colorScheme.tertiary,
                title: localizations.theme,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const ThemePickerDialog(),
                  );
                },
                isLast: true,
              );
            }

            return _buildDrawerItem(
              context: context,
              colorScheme: colorScheme,
              icon: null,
              customIcon:
                  getIconFromRegistry(menuOption.iconName) ??
                  const Icon(Icons.circle),
              title: menuOption.title,
              onTap: () {
                if (menuOption.route != null) {
                  Navigator.pop(context);
                  context.go(menuOption.route!);
                }
              },
              routeKey: 'tap${menuOption.route}',
            );
          },
        ),
      ),
    );
  }

  return Text(localizations.error);
}

/// Builds a styled drawer menu item with gradient hover effect
Widget _buildDrawerItem({
  required BuildContext context,
  required ColorScheme colorScheme,
  IconData? icon,
  Widget? customIcon,
  Color? iconColor,
  required String title,
  required VoidCallback onTap,
  String? routeKey,
  bool isLast = false,
}) {
  return Padding(
    padding: EdgeInsets.only(
      left: 12,
      right: 12,
      top: 4,
      bottom: isLast ? 20 : 4,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: routeKey != null ? Key(routeKey) : null,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: (iconColor ?? colorScheme.primary).withValues(
                    alpha: 0.1,
                  ),
                ),
                child: icon != null
                    ? Icon(
                        icon,
                        size: 22,
                        color: iconColor ?? colorScheme.primary,
                      )
                    : IconTheme(
                        data: IconThemeData(
                          size: 22,
                          color: colorScheme.primary,
                        ),
                        child: customIcon!,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
