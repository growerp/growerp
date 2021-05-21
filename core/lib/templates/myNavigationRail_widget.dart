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

import 'package:core/forms/@forms.dart';
import 'package:core/forms/user_dialog.dart';
import 'package:flutter/material.dart';
import 'package:models/@models.dart';

Widget myNavigationRail(BuildContext context, Authenticate authenticate,
    Widget widget, int? menuIndex, List<MenuItem>? menu) {
  List<NavigationRailDestination> items = [];
  menu?.forEach((option) => {
        if (option.readGroups.contains(authenticate.user?.userGroupId))
          items.add(NavigationRailDestination(
            icon: Image.asset(option.image,
                height: 40, key: Key('tap${option.route}')),
            selectedIcon: Image.asset(option.selectedImage),
            label: Text(option.title),
          )),
      });

  if (items.isEmpty)
    return FatalErrorForm("No access to any option here, "
        "have: ${authenticate.user?.userGroupId} should have: ${menu![0].readGroups}");

  return Row(children: <Widget>[
    LayoutBuilder(
      builder: (context, constraint) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraint.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                  key: Key('navigationrail'),
                  backgroundColor: Color(0xFF4baa9b),
                  leading: Center(
                      child: InkWell(
                          key: Key('tapUser'),
                          onTap: () async {
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return UserDialog(
                                      formArguments: FormArguments(
                                          object: authenticate.user));
                                });
                          },
                          child: Column(children: [
                            SizedBox(height: 5),
                            CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 15,
                                child: authenticate.user?.image != null
                                    ? Image.memory(authenticate.user!.image!)
                                    : Text(
                                        authenticate.user?.firstName
                                                ?.substring(0, 1) ??
                                            '',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.black))),
                            Text("${authenticate.user!.firstName} "
                                "${authenticate.user!.lastName}"),
                          ]))),
                  selectedIndex: menuIndex ?? 0,
                  onDestinationSelected: (int index) {
                    menuIndex = index;
                    if (menu![index].route == "/")
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          '/', (Route<dynamic> route) => false);
                    else
                      Navigator.pushNamed(context, menu[index].route,
                          arguments: FormArguments());
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle:
                      TextStyle(fontSize: 12, color: Colors.black),
                  unselectedLabelTextStyle:
                      TextStyle(fontSize: 12, color: Colors.black),
                  destinations: items),
            ),
          ),
        );
      },
    ),
    Expanded(child: widget)
  ]);
}
