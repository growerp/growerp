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

import '../../../domains/tasks/bloc/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class TimeEntryListHeader extends StatelessWidget {
  const TimeEntryListHeader({Key? key, required this.taskBloc})
      : super(key: key);
  final TaskBloc taskBloc;

  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
      title: Column(children: [
        Row(children: <Widget>[
          Expanded(child: Text("Date")),
          Container(child: Text("Hours")),
          if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
            Expanded(child: Text("From/To Party", textAlign: TextAlign.center)),
          if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
            Expanded(child: Text("Comments", textAlign: TextAlign.center)),
        ]),
        Divider(color: Colors.black),
      ]),
    ));
  }
}
