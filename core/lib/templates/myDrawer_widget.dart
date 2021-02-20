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

Widget myDrawer(BuildContext context, Authenticate authenticate, bool isPhone) {
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
  return loggedIn && isPhone
      ? Drawer(
          child: ListView.builder(
          itemCount: options.length + 1,
          itemBuilder: (context, i) {
            if (i == 0)
              return DrawerHeader(
                  child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/user',
                            arguments:
                                FormArguments(object: authenticate.user));
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
                      arguments:
                          FormArguments(menuIndex: options[i - 1]["tab"]));
                });
          },
        ))
      : null;
}
