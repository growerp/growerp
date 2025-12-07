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

Widget myNavigationRail(
  BuildContext context,
  Widget child,
  int menuIndex,
  List<MenuOption> menu,
) {
  final localizations = CoreLocalizations.of(context)!;
  List<NavigationRailDestination> items = [];
  ThemeBloc themeBloc = context.read<ThemeBloc>();
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;

  for (var option in menu) {
    // Try iconName first, then fall back to image paths (for top-level items)
    Widget iconWidget;
    Widget selectedIconWidget;

    if (option.iconName != null) {
      iconWidget =
          getIconFromRegistry(option.iconName) ??
          const Icon(Icons.circle, size: 40, key: Key('defaultIcon'));
      selectedIconWidget =
          getIconFromRegistry(option.iconName) ??
          const Icon(Icons.circle, size: 40);
    } else if (option.image != null) {
      // Use image assets for top-level menu items
      iconWidget = Image.asset(
        option.image!,
        width: 40,
        height: 40,
        key: Key('icon_${option.menuOptionId}'),
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
        icon: iconWidget,
        selectedIcon: selectedIconWidget,
        label: SizedBox(
          width: 80,
          child: Text(
            option.title,
            style: const TextStyle(fontSize: 14),
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
      SizedBox(
        width: 96,
        child: LayoutBuilder(
          builder: (context, constraint) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    key: const Key('navigationrail'),
                    leading: Center(
                      child: InkWell(
                        key: const Key('tapUser'),
                        onTap: () => context.go('/user', extra: auth?.user),
                        child: Column(
                          children: [
                            SizedBox(
                              height: ResponsiveBreakpoints.of(context).isTablet
                                  ? 25
                                  : 5,
                            ),
                            CircleAvatar(
                              radius: 15,
                              child: auth?.user?.image != null
                                  ? Image.memory(auth!.user!.image!)
                                  : Text(
                                      auth?.user?.firstName?.substring(0, 1) ??
                                          '',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                            ),
                            Text(auth?.user?.firstName ?? ''),
                            Text(auth?.user?.lastName ?? ''),
                          ],
                        ),
                      ),
                    ),
                    selectedIndex: menuIndex,
                    onDestinationSelected: (int index) {
                      if (index < menu.length && menu[index].route != null) {
                        context.go(menu[index].route!);
                      }
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: items,
                    groupAlignment: -0.85,
                    trailing: InkWell(
                      key: const Key('theme'),
                      onTap: () => themeBloc.add(ThemeSwitch()),
                      child: Column(
                        children: [
                          Icon(
                            size: 40,
                            themeBloc.state.themeMode == ThemeMode.light
                                ? Icons.light_mode
                                : Icons.dark_mode,
                          ),
                          Text(
                            localizations.theme,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Expanded(child: child),
    ],
  );
}
