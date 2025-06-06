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
import 'package:growerp_core/growerp_core.dart';

import '../bloc/task_bloc.dart';

class TimeEntryListHeader extends StatelessWidget {
  const TimeEntryListHeader({super.key, required this.taskBloc});
  final TaskBloc taskBloc;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(children: [
        Row(children: <Widget>[
          const Expanded(child: Text("Date")),
          const Text("Hours"),
          if (isPhone(context))
            const Expanded(
                child: Text("From/To Party", textAlign: TextAlign.center)),
          if (isPhone(context))
            const Expanded(
                child: Text("Comments", textAlign: TextAlign.center)),
        ]),
        const Divider(),
      ]),
    );
  }
}
