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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../blocs/ledger_bloc.dart';

/// Returns column definitions for time period list based on device type
List<StyledColumn> getTimePeriodListColumns(
  BuildContext context,
  OrderAccountingLocalizations localizations,
) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.name, flex: 2),
      StyledColumn(header: localizations.type, flex: 1),
      StyledColumn(header: localizations.year, flex: 1),
      StyledColumn(header: localizations.closed, flex: 1),
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    StyledColumn(header: localizations.name, flex: 2),
    StyledColumn(header: localizations.type, flex: 1),
    StyledColumn(header: localizations.from, flex: 2),
    StyledColumn(header: localizations.to, flex: 2),
    StyledColumn(header: localizations.closed, flex: 1),
    const StyledColumn(header: '', flex: 2), // Actions
  ];
}

/// Returns row data for time period list
List<Widget> getTimePeriodListRow({
  required BuildContext context,
  required TimePeriod timePeriod,
  required int index,
  required LedgerBloc ledgerBloc,
  required OrderAccountingLocalizations localizations,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  // Avatar
  cells.add(
    CircleAvatar(
      radius: 16,
      child: Text(
        timePeriod.periodName.length >= 5
            ? timePeriod.periodName.substring(3, 5)
            : timePeriod.periodName.isNotEmpty
            ? timePeriod.periodName.substring(0, 2)
            : '?',
        style: const TextStyle(fontSize: 12),
      ),
    ),
  );

  // Period name
  cells.add(Text(timePeriod.periodName, key: Key('name$index')));

  // Period type
  cells.add(Text(timePeriod.periodType, key: Key('type$index')));

  if (isPhone) {
    // Year only for phone
    cells.add(
      Text(
        timePeriod.fromDate.toString().substring(0, 4),
        key: Key('fromDate$index'),
        textAlign: TextAlign.center,
      ),
    );
  } else {
    // From date
    cells.add(
      Text(
        timePeriod.fromDate.toString().substring(0, 10),
        key: Key('fromDate$index'),
        textAlign: TextAlign.center,
      ),
    );

    // Thru date
    cells.add(
      Text(
        timePeriod.thruDate.toString().substring(0, 10),
        key: Key('thruDate$index'),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Closed status
  cells.add(
    Text(
      timePeriod.isClosed ? localizations.yes : localizations.no,
      key: Key('isClosed$index'),
      textAlign: TextAlign.center,
    ),
  );

  // Action buttons (desktop only)
  if (!isPhone) {
    List<Widget> buttons = [];

    if (timePeriod.hasPreviousPeriod ||
        timePeriod.hasNextPeriod ||
        timePeriod.isClosed) {
      buttons.add(
        IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
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

    if (!timePeriod.hasNextPeriod &&
        timePeriod.periodType == 'Y' &&
        !timePeriod.isClosed) {
      buttons.add(
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
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
          constraints: const BoxConstraints(),
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

    cells.add(Row(mainAxisSize: MainAxisSize.min, children: buttons));
  }

  return cells;
}
