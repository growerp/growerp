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
import 'package:responsive_framework/responsive_framework.dart';
import '../domains/domains.dart';

Widget myNavigationRail(
    BuildContext context, Widget child, int menuIndex, List<MenuOption> menu) {
  List<NavigationRailDestination> items = [];
  ThemeBloc themeBloc = context.read<ThemeBloc>();
  AuthBloc authBloc = context.read<AuthBloc>();
  Authenticate? auth = authBloc.state.authenticate;
  for (var option in menu) {
    items.add(NavigationRailDestination(
      icon: Image.asset(
          option.image ?? 'packages/growerp_core/images/selectGrey.png',
          height: 40,
          key: Key('tap${option.route}')),
      selectedIcon: Image.asset(
          option.selectedImage ?? 'packages/growerp_core/images/select.png'),
      label: Text(option.title),
    ));
  }
  if (items.isEmpty) {
    return const FatalErrorForm(message: "No access to any option here, ");
  }

  return Row(children: <Widget>[
    LayoutBuilder(
      builder: (context, constraint) {
        return SingleChildScrollView(
            child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                child: IntrinsicHeight(
                    child: NavigationRail(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        key: const Key('navigationrail'),
                        leading: Center(
                            child: InkWell(
                                key: const Key('tapUser'),
                                onTap: () => Navigator.pushNamed(
                                    context, '/user',
                                    arguments: auth.user),
                                child: Column(children: [
                                  SizedBox(
                                      height: ResponsiveBreakpoints.of(context)
                                              .isTablet
                                          ? 25
                                          : 5),
                                  CircleAvatar(
                                      radius: 15,
                                      child: auth!.user?.image != null
                                          ? Image.memory(auth.user!.image!)
                                          : Text(
                                              auth.user?.firstName
                                                      ?.substring(0, 1) ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ))),
                                  Text("${auth.user!.firstName}"),
                                  Text("${auth.user!.lastName}"),
                                ]))),
                        selectedIndex: menuIndex,
                        onDestinationSelected: (int index) {
                          menuIndex = index;
                          if (menu[index].route != null) {
                            if (menu[index].route == "/") {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/', (Route<dynamic> route) => false,
                                  arguments: menu[index].arguments);
                            } else {
                              Navigator.pushNamed(context, menu[index].route!,
                                  arguments: menu[index].arguments);
                            }
                          }
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: items,
                        groupAlignment: -0.85,
                        trailing: InkWell(
                            key: const Key('theme'),
                            onTap: () => themeBloc.add(ThemeSwitch()),
                            child: Column(children: [
                              Icon(themeBloc.state.themeMode == ThemeMode.light
                                  ? Icons.light_mode
                                  : Icons.dark_mode),
                              const Text("Theme"),
                            ]))))));
      },
    ),
    Expanded(child: child)
  ]);
}
