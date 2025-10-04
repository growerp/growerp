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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../accounting.dart';

class TimePeriodListItem extends StatelessWidget {
  const TimePeriodListItem({
    super.key,
    required this.timePeriod,
    required this.index,
  });

  final TimePeriod timePeriod;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ledgerBloc = context.read<LedgerBloc>();
    final localizations = OrderAccountingLocalizations.of(context)!;

    List<Widget> buttons = [];
    if (timePeriod.hasPreviousPeriod ||
        timePeriod.hasNextPeriod ||
        timePeriod.isClosed) {
      buttons.add(
        IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          padding: EdgeInsets.zero,
          tooltip: localizations.deletePeriod,
          onPressed: () {
            ledgerBloc.add(
              LedgerTimePeriodsUpdate(
                delete: true,
                timePeriodId: timePeriod.periodId,
              ),
            );
          },
        ),
      );
    }
    /*    if (!timePeriod.hasPreviousPeriod) { not working in backend....?
      buttons.add(IconButton(
          key: Key('previous$index'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'create previous period',
          onPressed: () {
            ledgerBloc.add(LedgerTimePeriodsUpdate(
                createPrevious: true, timePeriodId: timePeriod.periodId));
          }));
    }
*/
    if (!timePeriod.hasNextPeriod &&
        timePeriod.periodType == 'Y' &&
        !timePeriod.isClosed) {
      buttons.add(
        IconButton(
          padding: EdgeInsets.zero,
          key: Key('next$index'),
          icon: const Icon(Icons.arrow_forward),
          tooltip: localizations.createNextPeriod,
          onPressed: () {
            ledgerBloc.add(
              LedgerTimePeriodsUpdate(
                createNext: true,
                timePeriodId: timePeriod.periodId,
                timePeriodName: timePeriod.periodName,
              ),
            );
          },
        ),
      );
    }

    if (!timePeriod.isClosed) {
      buttons.add(
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          key: Key('close$index'),
          icon: const Icon(Icons.close),
          tooltip: localizations.closeTimePeriod,
          onPressed: () async {
            bool? result = await confirmDialog(
              context,
              localizations.closeTimePeriodConfirmation(timePeriod.periodName),
              localizations.cannotBeUndone,
            );
            if (result == true) {
              ledgerBloc.add(
                LedgerTimePeriodClose(
                  timePeriod.periodId,
                  timePeriodName: timePeriod.periodName,
                ),
              );
            }
          },
        ),
      );
    }

    return ListTile(
      leading: CircleAvatar(child: Text(timePeriod.periodName.substring(3, 5))),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text("${timePeriod.periodName}", key: Key('name$index')),
          ),
          Expanded(
            child: Text("${timePeriod.periodType}", key: Key('type$index')),
          ),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            Expanded(
              child: Text(
                "${timePeriod.fromDate.toString().substring(0, 10)}",
                key: Key('fromDate$index'),
                textAlign: TextAlign.center,
              ),
            ),
          if (ResponsiveBreakpoints.of(context).equals(MOBILE))
            Expanded(
              child: Text(
                "${timePeriod.fromDate.toString().substring(0, 4)}",
                key: Key('fromDate$index'),
                textAlign: TextAlign.center,
              ),
            ),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            Expanded(
              child: Text(
                "${timePeriod.thruDate.toString().substring(0, 10)}",
                key: Key('thruDate$index'),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Text(
              timePeriod.isClosed ? localizations.yes : localizations.no,
              key: Key('isClosed$index'),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      trailing: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
          ? SizedBox(width: 180, child: Row(children: buttons))
          : null,
    );
  }
}
