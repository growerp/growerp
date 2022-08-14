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

class UserListHeader extends StatefulWidget {
  const UserListHeader({
    Key? key,
    required this.userGroup,
    required this.isPhone,
    required this.userBloc,
  }) : super(key: key);
  final UserGroup userGroup;
  final bool isPhone;
  final UserBloc userBloc;

  @override
  State<UserListHeader> createState() => _UserListHeaderState();
}

class _UserListHeaderState extends State<UserListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
            leading: GestureDetector(
                key: Key('search'),
                onTap: (() =>
                    setState(() => search ? search = false : search = true)),
                child: Image.asset(
                  'assets/images/search.png',
                  height: 30,
                )),
            title: search
                ? Row(children: <Widget>[
                    Expanded(
                        child: TextField(
                      key: Key('searchField'),
                      autofocus: true,
                      decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          hintText: 'enter first or last name'),
                      onChanged: ((value) {
                        searchString = value;
                      }),
                    )),
                    ElevatedButton(
                        key: Key('searchButton'),
                        child: Text('search'),
                        onPressed: () {
                          widget.userBloc
                              .add(UserFetch(searchString: searchString));
                          searchString = '';
                        })
                  ])
                : Row(
                    children: <Widget>[
                      Expanded(child: Text("Name")),
                      if (!widget.isPhone) Expanded(child: Text("login name")),
                      if (!widget.isPhone) Expanded(child: Text("Email")),
                      if (!widget.isPhone) Expanded(child: Text("Language")),
                      if (!widget.isPhone &&
                          widget.userGroup != UserGroup.Employee &&
                          widget.userGroup != UserGroup.Admin)
                        Expanded(
                            child:
                                Text("Company", textAlign: TextAlign.center)),
                      if (widget.isPhone &&
                          widget.userGroup != UserGroup.Employee &&
                          widget.userGroup != UserGroup.Admin)
                        Expanded(child: Text("Company"))
                    ],
                  ),
            trailing: Text(' ')));
  }
}
