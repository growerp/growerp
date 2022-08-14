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

import 'package:core/domains/domains.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final int index;
  final UserGroup userGroup;
  final UserBloc userBloc;
  final bool isDeskTop;

  const UserListItem({
    Key? key,
    required this.user,
    required this.index,
    required this.userGroup,
    required this.userBloc,
    required this.isDeskTop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: user.image != null
                  ? Image.memory(user.image!)
                  : Text(user.firstName![0]),
            ),
            subtitle: !isDeskTop
                ? Text(
                    user.email != null && user.email!.contains('example.com')
                        ? " "
                        : "${user.email}",
                    key: Key("email$index"))
                : null,
            title: Row(
              children: <Widget>[
                Expanded(
                    child: Text(
                  "${user.firstName} "
                  "${user.lastName}",
                  key: Key('name$index'),
                )),
                if (isDeskTop)
                  Expanded(
                      child: Text(
                          (!user.loginDisabled! ? "${user.loginName}" : " "),
                          key: Key('username$index'))),
                if (isDeskTop)
                  Expanded(
                      child: Text(
                    user.email!.contains('example.com') ? " " : "${user.email}",
                    key: Key('email$index'),
                  )),
                if (isDeskTop)
                  Expanded(
                      child: Text(
                    "${user.language ?? ''}",
                    key: Key('language$index'),
                  )),
                if (isDeskTop &&
                    userGroup != UserGroup.Employee &&
                    userGroup != UserGroup.Admin)
                  Expanded(
                    child: Text("${user.companyName}",
                        key: Key('companyName$index'),
                        textAlign: TextAlign.center),
                  ),
                if (!isDeskTop &&
                    userGroup != UserGroup.Employee &&
                    userGroup != UserGroup.Admin)
                  Expanded(
                      child: Text("${user.companyName}",
                          key: Key('companyName$index'),
                          textAlign: TextAlign.center))
              ],
            ),
            onTap: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider.value(
                        value: userBloc, child: UserDialog(user: user));
                  });
            },
            trailing: IconButton(
              key: Key("delete$index"),
              icon: Icon(Icons.delete_forever),
              onPressed: () {
                userBloc.add(UserDelete(user.copyWith(image: null)));
              },
            )));
  }
}
