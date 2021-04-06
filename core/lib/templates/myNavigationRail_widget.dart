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
import 'package:models/@models.dart';
import '';

Widget myNavigationRail(BuildContext context, Authenticate authenticate,
    Widget widget, int? menuIndex, List<MenuItem>? menu, int menuCompany) {
  List<NavigationRailDestination> items = [];
  menu?.forEach((option) => {
        if (option.readGroups!.contains(authenticate.user?.userGroupId))
          items.add(NavigationRailDestination(
            icon: Image.asset(option.image!, height: 40),
            selectedIcon: Image.asset(option.selectedImage!),
            label: Text(option.title!),
          )),
      });

  return Row(children: <Widget>[
    NavigationRail(
        backgroundColor: Color(0xFF4baa9b),
        leading: Center(
            child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/user',
                      arguments: FormArguments(
                          object: authenticate.user, menuIndex: menuCompany));
                },
                child: Column(children: [
                  SizedBox(height: 5),
                  CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 15,
                      child: authenticate.user?.image != null
                          ? Image.memory(authenticate.user!.image!)
                          : Text(
                              authenticate.user?.firstName?.substring(0, 1) ??
                                  '',
                              style: TextStyle(
                                  fontSize: 20, color: Colors.black))),
                  Text("${authenticate.user!.firstName} "
                      "${authenticate.user!.lastName}"),
                ]))),
        selectedIndex: menuIndex ?? 0,
        onDestinationSelected: (int index) {
          menuIndex = index;
          if (menu![index].route == "/")
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
          else
            Navigator.pushNamed(context, menu[index].route!,
                arguments: FormArguments());
        },
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: TextStyle(fontSize: 12, color: Colors.black),
        unselectedLabelTextStyle: TextStyle(fontSize: 12, color: Colors.black),
        destinations: items),
    Expanded(child: widget)
  ]);
}
