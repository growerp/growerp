/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:growerp_models/growerp_models.dart';

import '../blocs/ledger_journal_bloc.dart';

/// Returns column definitions for ledger journal list based on device type
List<StyledColumn> getLedgerJournalListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return [
      const StyledColumn(header: '', flex: 1), // Avatar
      const StyledColumn(header: 'Journal Name', flex: 3),
      const StyledColumn(header: 'Posted Date', flex: 2),
      const StyledColumn(header: 'Posted', flex: 1),
      const StyledColumn(header: '', flex: 1), // Post action
    ];
  }

  return [
    const StyledColumn(header: '', flex: 1), // Avatar
    const StyledColumn(header: 'Journal Name', flex: 3),
    const StyledColumn(header: 'Posted Date', flex: 2),
    const StyledColumn(header: 'Posted', flex: 1),
    const StyledColumn(header: 'Error?', flex: 1),
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
