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
import '../domains/domains.dart';

Widget? myDrawer(BuildContext context, Authenticate authenticate, bool isPhone,
    List<MenuOption>? menu) {
  UserGroup? groupId = authenticate.user?.userGroup;
  List options = [];
  menu?.forEach((option) => {
        if (option.readGroups.contains(groupId))
          options.add({
            "route": option.route,
            "selImage": option.selectedImage,
            "title": option.title,
          }),
      });
  bool loggedIn = authenticate.apiKey != null;
  if (loggedIn && isPhone) {
    return SizedBox(
        width: MediaQuery.of(context).size.width * 0.40,
        child: Drawer(
          key: const Key('drawer'),
          child: ListView.builder(
            itemCount: options.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return DrawerHeader(
                    child: InkWell(
                        key: const Key('tapUser'),
                        onTap: () => Navigator.pushNamed(context, '/user',
                            arguments: authenticate.user),
                        child: Column(children: [
                          CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 40,
                              child: authenticate.user?.image != null
                                  ? Image.memory(authenticate.user!.image!)
                                  : Text(
                                      authenticate.user?.firstName
                                              ?.substring(0, 1) ??
                                          '',
                                      style: const TextStyle(
                                          fontSize: 30, color: Colors.black))),
                          const SizedBox(height: 10),
                          Text("${authenticate.user!.firstName} ",
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black)),
                          Text("${authenticate.user!.lastName}",
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black)),
                        ])));
              }
              return ListTile(
                  key: Key('tap${options[i - 1]["route"]}'),
                  contentPadding: const EdgeInsets.all(5.0),
                  title: Text(options[i - 1]["title"]),
                  leading: Image.asset(
                    options[i - 1]["selImage"],
                  ),
                  onTap: () {
                    if (options[i - 1]["route"] == "/") {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          '/', (Route<dynamic> route) => false);
                    } else {
                      Navigator.pushNamed(context, options[i - 1]["route"],
                          arguments:
                              FormArguments(menuIndex: options[i - 1]["tab"]));
                    }
                  });
            },
          ),
        ));
  }
  return const Text('error: should not arrive here');
}
