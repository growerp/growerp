// ignore_for_file: depend_on_referenced_packages

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
import 'package:growerp_models/growerp_models.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class BalanceSummaryListHeader extends StatefulWidget {
  const BalanceSummaryListHeader(
      this.controller, this.ledgerReport, this.isPhone,
      {super.key});
  final ItemScrollController controller;
  final LedgerReport ledgerReport;
  final bool isPhone;
  @override
  State<BalanceSummaryListHeader> createState() =>
      _BalanceSummaryListHeaderState();
}

class _BalanceSummaryListHeaderState extends State<BalanceSummaryListHeader> {
  String searchString = '';
  bool search = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: GestureDetector(
            key: const Key('search'),
            onTap: (() => setState(() => search = !search)),
            child: const Icon(Icons.search_sharp, size: 40)),
        title: search
            ? Row(children: <Widget>[
                Expanded(
                    child: TextField(
                  key: const Key('searchField'),
                  autofocus: true,
                  decoration: const InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    hintText: "search in account code and name...",
                  ),
                  onChanged: ((value) => setState(() => searchString = value)),
                )),
                OutlinedButton(
                    key: const Key('searchButton'),
                    child: const Text('Search'),
                    onPressed: () async {
                      int index = 0;
                      for (var el in widget.ledgerReport.glAccounts) {
                        if (el.accountCode!.contains(searchString) ||
                            el.accountName!.contains(searchString)) {
                          break;
                        }
                        index++;
                      }
                      widget.controller.scrollTo(
                          index: index,
                          duration: const Duration(seconds: 1),
                          curve: Curves.linear);
                    })
              ])
            : Column(children: [
                if (widget.isPhone)
                  const Text("Account Name", textAlign: TextAlign.center),
                Row(children: <Widget>[
                  const Expanded(
                      child: Text("Code", textAlign: TextAlign.center)),
                  if (!widget.isPhone)
                    const Expanded(
                        child: Text("Name", textAlign: TextAlign.center)),
                  const Expanded(
                      child: Text("Begin", textAlign: TextAlign.right)),
                  if (!widget.isPhone)
                    const Expanded(
                        child:
                            Text("Post.\nDebit", textAlign: TextAlign.right)),
                  if (!widget.isPhone)
                    const Expanded(
                        child:
                            Text("Post.\nCredt", textAlign: TextAlign.right)),
                  const Expanded(
                      child: Text("End Bal.", textAlign: TextAlign.right)),
                ]),
                const Divider(),
              ]),
        trailing: const Text(' '));
  }
}
