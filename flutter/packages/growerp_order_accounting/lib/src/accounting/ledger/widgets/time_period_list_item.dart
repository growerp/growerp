// ignore_for_file: unnecessary_string_interpolations

/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
