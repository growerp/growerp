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

Widget? myDrawer(BuildContext context, bool isPhone, List<MenuItem> menu) {
  final localizations = CoreLocalizations.of(context)!;
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
      width: 200,
      key: const Key('drawer'),
      child: ListView.builder(
        key: const Key('listView'),
        itemCount: options.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return DrawerHeader(
              child: InkWell(
                key: const Key('tapUser'),
                onTap: () => context.go('/user', extra: auth?.user),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: auth?.user?.image != null
                          ? Image.memory(auth!.user!.image!)
                          : Text(
                              auth?.user?.firstName?.substring(0, 1) ?? '',
                              style: const TextStyle(fontSize: 30),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${auth?.user!.firstName} ",
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      "${auth?.user!.lastName}",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }

          final menuOption = options[i - 1];

          if (menuOption.route == "theme") {
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: InkWell(
                key: const Key('theme'),
                onTap: () {
                  Navigator.pop(context); // Close drawer first
                  showDialog(
                    context: context,
                    builder: (context) => const ThemePickerDialog(),
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 5),
                    const Icon(Icons.palette, size: 40),
                    const SizedBox(width: 20),
                    Text(
                      localizations.theme,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListTile(
            key: Key('tap${menuOption.route}'),
            contentPadding: const EdgeInsets.all(5.0),
            title: Text(
              menuOption.title,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            leading:
                getIconFromRegistry(menuOption.iconName) ??
                const Icon(Icons.circle),
            onTap: () {
              if (menuOption.route != null) {
                // Close drawer first
                Navigator.pop(context);
                // Then navigate
                context.go(menuOption.route!);
              }
            },
          );
        },
      ),
    );
  }

  return Text(localizations.error);
}
