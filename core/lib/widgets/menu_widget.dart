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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:models/models.dart';
import '../routing_constants.dart';

Widget myDrawer(BuildContext context, Authenticate authenticate) {
  String groupId = authenticate?.user?.userGroupId;
  List options = [];
  menuItems.forEach((option) => {
        if (option.readGroups.contains(groupId))
          options.add({
            "route": option.route,
            "selImage": option.selectedImage,
            "title": option.title,
          }),
      });
  bool loggedIn = authenticate?.apiKey != null;
  return (loggedIn && ResponsiveWrapper.of(context).isSmallerThan(TABLET))
      ? Drawer(
          child: ListView.builder(
          itemCount: options.length + 1,
          itemBuilder: (context, i) {
            if (i == 0)
              return DrawerHeader(
                  child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, UserRoute,
                            arguments: FormArguments(null, authenticate.user));
                      },
                      child: Column(children: [
                        CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 40,
                            child: authenticate?.user?.image != null
                                ? Image.memory(authenticate.user?.image)
                                : Text(
                                    authenticate.user?.firstName
                                            ?.substring(0, 1) ??
                                        '',
                                    style: TextStyle(
                                        fontSize: 30, color: Colors.black))),
                        SizedBox(height: 20),
                        Text(
                            "${authenticate.user.firstName} "
                            "${authenticate.user.lastName}",
                            style:
                                TextStyle(fontSize: 20, color: Colors.black)),
                      ])));
            return ListTile(
                contentPadding: EdgeInsets.all(5.0),
                title: Text(options[i - 1]["title"]),
                leading: Image.asset(
                  options[i - 1]["selImage"],
                ),
                onTap: () {
                  Navigator.pushNamed(context, options[i - 1]["route"],
                      arguments: FormArguments());
                });
          },
        ))
      : null;
}

Widget myNavigationRail(context, authenticate, widget, selectedIndex) {
  List<NavigationRailDestination> items = [];
  menuItems.forEach((option) => {
        if (option.readGroups.contains(authenticate.user.userGroupId))
          items.add(NavigationRailDestination(
            icon: Image.asset(option.image, height: 40),
            selectedIcon: Image.asset(option.selectedImage),
            label: Text(option.title),
          )),
      });

  return Row(children: <Widget>[
    NavigationRail(
        backgroundColor: Color(0xFF4baa9b),
        leading: Center(
            child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, UserRoute,
                      arguments: FormArguments(null, authenticate.user));
                },
                child: Column(children: [
                  SizedBox(height: 5),
                  CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 15,
                      child: authenticate.user?.image != null
                          ? Image.memory(authenticate?.user?.image)
                          : Text(
                              authenticate?.user?.firstName?.substring(0, 1) ??
                                  '',
                              style: TextStyle(
                                  fontSize: 20, color: Colors.black))),
                  Text("${authenticate.user.firstName} "
                      "${authenticate.user.lastName}"),
                ]))),
        selectedIndex: selectedIndex ?? 0,
        onDestinationSelected: (int index) {
          selectedIndex = index;
          Navigator.pushNamed(context, menuItems[index].route,
              arguments: FormArguments());
        },
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: TextStyle(fontSize: 12, color: Colors.black),
        unselectedLabelTextStyle: TextStyle(fontSize: 12, color: Colors.black),
        destinations: items),
    Expanded(child: widget)
  ]);
}
