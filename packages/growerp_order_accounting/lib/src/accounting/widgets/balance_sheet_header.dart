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
import 'package:growerp_core/growerp_core.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class BalanceSheetHeader extends StatefulWidget {
  const BalanceSheetHeader(this.controller, this.accounts, {Key? key})
      : super(key: key);
  final ItemScrollController controller;
  final List<GlAccount> accounts;
  @override
  State<BalanceSheetHeader> createState() => _BalanceSheetHeaderState();
}

class _BalanceSheetHeaderState extends State<BalanceSheetHeader> {
  String searchString = '';
  bool search = false;

  @override
  Widget build(BuildContext context) {
    return Material(
        child: ListTile(
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
                      onChanged: ((value) =>
                          setState(() => searchString = value)),
                    )),
                    ElevatedButton(
                        key: const Key('searchButton'),
                        child: const Text('Search'),
                        onPressed: () async {
                          int index = 0;
                          for (var el in widget.accounts) {
                            if (el.accountCode!.contains(searchString) ||
                                el.accountCode!.contains(searchString)) {
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
                : const Column(children: [
                    Row(children: <Widget>[
                      Expanded(
                          child:
                              Text("Code/Name", textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("Beginning Balance",
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("Posted Debits",
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("Posted Credits",
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("Ending Balance",
                              textAlign: TextAlign.center)),
                    ]),
                    Divider(),
                  ]),
            trailing: const Text(' ')));
  }
}
