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

import '../blocs/ledger_journal_bloc.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

/// Returns column definitions for ledger journal list based on device type
List<StyledColumn> getLedgerJournalListColumns(BuildContext context) {
  final localizations = OrderAccountingLocalizations.of(context)!;
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      StyledColumn(header: localizations.tableHdrJournalName, flex: 3),
      StyledColumn(header: localizations.tableHdrPostedDate, flex: 2),
      StyledColumn(header: localizations.postedHeader, flex: 1),
      const StyledColumn(header: '', flex: 1), // Post action
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    StyledColumn(header: localizations.tableHdrJournalName, flex: 3),
    StyledColumn(header: localizations.tableHdrPostedDate, flex: 2),
    StyledColumn(header: localizations.postedHeader, flex: 1),
    StyledColumn(header: localizations.tableHdrError, flex: 1),
    const StyledColumn(header: '', flex: 1), // Post action
  ];
}

/// Returns row data for ledger journal list
List<Widget> getLedgerJournalListRow({
  required BuildContext context,
  required LedgerJournal ledgerJournal,
  required int index,
  required LedgerJournalBloc ledgerJournalBloc,
}) {
  bool isPhone = isAPhone(context);
  List<Widget> cells = [];

  // Avatar
  cells.add(
    CircleAvatar(
      radius: 16,
      child: Text(
        ledgerJournal.journalId.isEmpty
            ? '?'
            : ledgerJournal.journalId.lastChar(3),
        style: const TextStyle(fontSize: 10),
      ),
    ),
  );

  // Journal name
  cells.add(
    Text(
      ledgerJournal.journalName,
      key: Key('name$index'),
      overflow: TextOverflow.ellipsis,
    ),
  );

  // Posted date
  cells.add(
    Text(
      ledgerJournal.postedDate == null
          ? ''
          : ledgerJournal.postedDate.toString().substring(0, 10),
      key: Key('postedDate$index'),
      textAlign: TextAlign.center,
    ),
  );

  // Is Posted
  cells.add(
    Text(
      ledgerJournal.isPosted == true ? 'Y' : 'N',
      key: Key('isPosted$index'),
      textAlign: TextAlign.center,
    ),
  );

  // Is Error (desktop only)
  if (!isPhone) {
    cells.add(
      Text(
        ledgerJournal.isError == true ? 'Y' : 'N',
        key: Key('isError$index'),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Post action button
  cells.add(
    GestureDetector(
      key: Key('post$index'),
      child: Text(
        'POST',
        style: TextStyle(
          color: ledgerJournal.isPosted == false
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: ledgerJournal.isPosted == false
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: () async {
        if (ledgerJournal.isPosted == false) {
          ledgerJournalBloc.add(
            LedgerJournalUpdate(ledgerJournal.copyWith(isPosted: true)),
          );
        }
      },
    ),
  );

  return cells;
}
