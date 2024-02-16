// ignore_for_file: unnecessary_string_interpolations

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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../accounting.dart';

class TimePeriodListItem extends StatelessWidget {
  const TimePeriodListItem(
      {super.key, required this.timePeriod, required this.index});

  final TimePeriod timePeriod;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ledgerBloc = context.read<LedgerBloc>();

    List<Widget> buttons = [];
    if (!timePeriod.hasPreviousPeriod) {
      buttons.add(IconButton(
          key: Key('previous$index'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ledgerBloc.add(LedgerTimePeriods(
                createPrevious: true, currentPeriodId: timePeriod.periodId));
          }));
    }
    if (!timePeriod.hasNextPeriod) {
      buttons.add(IconButton(
          key: Key('next$index'),
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            ledgerBloc.add(LedgerTimePeriods(
                createNext: true, currentPeriodId: timePeriod.periodId));
          }));
    }
    buttons.add(IconButton(
        key: Key('delete$index'),
        icon: const Icon(Icons.delete_forever),
        onPressed: () {
          ledgerBloc.add(LedgerTimePeriods(
              deleteCurrent: true, currentPeriodId: timePeriod.periodId));
        }));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(timePeriod.periodName.substring(3, 5)),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
              child: Text("${timePeriod.periodName}", key: Key('name$index'))),
          Expanded(
              child: Text("${timePeriod.periodType}", key: Key('type$index'))),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            Expanded(
                child: Text(
                    "${timePeriod.fromDate.toString().substring(0, 10)}",
                    key: Key('fromDate$index'),
                    textAlign: TextAlign.center)),
          if (ResponsiveBreakpoints.of(context).equals(MOBILE))
            Expanded(
                child: Text("${timePeriod.fromDate.toString().substring(0, 4)}",
                    key: Key('fromDate$index'), textAlign: TextAlign.center)),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            Expanded(
                child: Text(
                    "${timePeriod.thruDate.toString().substring(0, 10)}",
                    key: Key('thruDate$index'),
                    textAlign: TextAlign.center)),
          Expanded(
              child: Text(timePeriod.isClosed ? 'Y' : 'N',
                  key: Key('isClosed$index'), textAlign: TextAlign.center)),
        ],
      ),
      trailing: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
          ? SizedBox(width: 180, child: Row(children: buttons))
          : null,
    );
  }
}
