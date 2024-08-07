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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../ledger_journal.dart';

class LedgerJournalListHeader extends StatefulWidget {
  const LedgerJournalListHeader({super.key});

  @override
  State<LedgerJournalListHeader> createState() =>
      _LedgerJournalListHeaderState();
}

class _LedgerJournalListHeaderState extends State<LedgerJournalListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: GestureDetector(
            key: const Key('search'),
            onTap: (() =>
                setState(() => search ? search = false : search = true)),
            child: const Icon(Icons.search_sharp, size: 40)),
        title: search
            ? Row(children: <Widget>[
                SizedBox(
                    width: ResponsiveBreakpoints.of(context).isMobile
                        ? MediaQuery.of(context).size.width - 250
                        : MediaQuery.of(context).size.width - 350,
                    child: TextField(
                      key: const Key('searchField'),
                      autofocus: true,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        hintText: "search in ID, name and lead...",
                      ),
                      onChanged: ((value) => setState(() {
                            searchString = value;
                          })),
                    )),
                OutlinedButton(
                    key: const Key('searchButton'),
                    child: const Text('Search'),
                    onPressed: () {
                      context
                          .read<LedgerJournalBloc>()
                          .add(LedgerJournalFetch(searchString: searchString));
                    })
              ])
            : Column(children: [
                if (ResponsiveBreakpoints.of(context).isMobile)
                  const Text("Journal Name"),
                Row(children: <Widget>[
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                    const Expanded(child: Text("Journal Name")),
                  const Expanded(
                      child: Text("Posted date", textAlign: TextAlign.center)),
                  const Expanded(
                      child: Text("Posted?", textAlign: TextAlign.center)),
                  const Expanded(
                      child:
                          Text("Error Journal?", textAlign: TextAlign.center)),
                ]),
                const Divider(),
              ]),
        trailing: search ? null : const SizedBox(width: 20));
  }
}
