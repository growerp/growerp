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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

class LedgerJournalListItem extends StatelessWidget {
  const LedgerJournalListItem({
    super.key,
    required this.ledgerJournal,
    required this.index,
  });

  final LedgerJournal ledgerJournal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ledgerJournalBloc = context.read<LedgerJournalBloc>();
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          ledgerJournal.journalId.isEmpty
              ? ''
              : ledgerJournal.journalId.lastChar(3),
        ),
      ),
      title: Column(
        children: [
          if (ResponsiveBreakpoints.of(context).isMobile)
            Text(ledgerJournal.journalName, key: Key('name$index')),
          Row(
            children: <Widget>[
              if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                Expanded(
                  child: Text(
                    ledgerJournal.journalName,
                    key: Key('name$index'),
                  ),
                ),
              Expanded(
                child: Text(
                  ledgerJournal.postedDate == null
                      ? ''
                      : ledgerJournal.postedDate.toString(),
                  key: Key('postedDate$index'),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  ledgerJournal.isPosted == true ? 'Y' : 'N',
                  key: Key('isPosted$index'),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  ledgerJournal.isError == true ? 'Y' : 'N',
                  key: Key('isError$index'),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () async {
        await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) => BlocProvider.value(
            value: ledgerJournalBloc,
            child: LedgerJournalDialog(ledgerJournal),
          ),
        );
      },
      trailing: GestureDetector(
        child: Text(OrderAccountingLocalizations.of(context)!.post),
        onTap: () async {
          if (ledgerJournal.isPosted == false) {
            ledgerJournalBloc.add(
              LedgerJournalUpdate(ledgerJournal.copyWith(isPosted: true)),
            );
          }
        },
      ),
    );
  }
}
