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
import 'package:growerp_models/growerp_models.dart';
import '../domains/domains.dart';

Widget? myDrawer(BuildContext context, bool isPhone, List<MenuOption> menu) {
  ThemeBloc themeBloc = context.read<ThemeBloc>();
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;
  List<MenuOption> options = [];
  for (var option in menu) {
    {
      if (access(auth?.user?.userGroup!, option)) {
        options.add(option);
      }
    }
  }
  options.add(MenuOption(route: 'theme', title: 'Theme', readGroups: []));
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
                    onTap: () => Navigator.pushNamed(context, '/user',
                        arguments: auth?.user),
                    child: Column(children: [
                      CircleAvatar(
                          radius: 40,
                          child: auth?.user?.image != null
                              ? Image.memory(auth!.user!.image!)
                              : Text(
                                  auth?.user?.firstName?.substring(0, 1) ?? '',
                                  style: const TextStyle(fontSize: 30))),
                      const SizedBox(height: 10),
                      Text("${auth?.user!.firstName} ",
                          style: const TextStyle(fontSize: 15)),
                      Text("${auth?.user!.lastName}",
                          style: const TextStyle(
                            fontSize: 15,
                          )),
                    ])));
          }
          if (options[i - 1].route == "theme") {
            return InkWell(
                key: const Key('theme'),
                onTap: () => themeBloc.add(ThemeSwitch()),
                child: Column(children: [
                  Icon(themeBloc.state.themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  const Text("Theme"),
                ]));
          }
          return ListTile(
              key: Key('tap${options[i - 1].route}'),
              contentPadding: const EdgeInsets.all(5.0),
              title: Text(options[i - 1].title),
              leading: Image.asset(
                options[i - 1].selectedImage ??
                    'packages/growerp_core/images/select.png',
              ),
              onTap: () {
                if (options[i - 1].route == "/") {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (Route<dynamic> route) => false,
                      arguments: options[i - 1].arguments);
                } else {
                  Navigator.pushNamed(context, options[i - 1].route!,
                      arguments: options[i - 1].arguments);
                }
              });
        },
      ),
    );
  }
  return const Text('error: should not arrive here');
}
