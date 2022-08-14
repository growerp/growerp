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

import 'package:core/domains/tasks/bloc/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class TaskListHeader extends StatefulWidget {
  const TaskListHeader({Key? key}) : super(key: key);

  @override
  State<TaskListHeader> createState() => _TaskListHeaderState();
}

class _TaskListHeaderState extends State<TaskListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
          onTap: (() =>
              setState(() => search ? search = false : search = true)),
          leading: Image.asset('assets/images/search.png', height: 30),
          title: search
              ? Row(children: <Widget>[
                  SizedBox(
                      width: ResponsiveWrapper.of(context).isSmallerThan(TABLET)
                          ? MediaQuery.of(context).size.width - 250
                          : MediaQuery.of(context).size.width - 350,
                      child: TextField(
                        textInputAction: TextInputAction.go,
                        autofocus: true,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          hintText: "search in name and description...",
                        ),
                        onChanged: ((value) =>
                            setState(() => searchString = value)),
                      )),
                  ElevatedButton(
                      child: Text('Search'),
                      onPressed: () {
                        context
                            .read<TaskBloc>()
                            .add(TaskFetch(searchString: searchString));
                      })
                ])
              : Column(children: [
                  Row(children: <Widget>[
                    Expanded(child: Text("Name")),
                    Expanded(child: Text("Status")),
                    Container(child: Text("Hours")),
                    if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                      Expanded(
                          child: Text("From/To Party",
                              textAlign: TextAlign.center)),
                  ]),
                  Divider(color: Colors.black),
                ]),
          trailing: search ? null : SizedBox(width: 20)),
    );
  }
}
