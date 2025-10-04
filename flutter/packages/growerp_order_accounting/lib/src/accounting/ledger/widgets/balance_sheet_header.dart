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
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

class BalanceSheetHeader extends StatefulWidget {
  const BalanceSheetHeader(this.controller, this.accounts, {super.key});
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
    final localizations = OrderAccountingLocalizations.of(context)!;
    return ListTile(
      leading: GestureDetector(
        key: const Key('search'),
        onTap: (() => setState(() => search = !search)),
        child: const Icon(Icons.search_sharp, size: 40),
      ),
      title: search
          ? Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('searchField'),
                    autofocus: true,
                    decoration: InputDecoration(
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      hintText: localizations.search,
                    ),
                    onChanged: ((value) =>
                        setState(() => searchString = value)),
                  ),
                ),
                OutlinedButton(
                  key: const Key('searchButton'),
                  child: Text(localizations.search),
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
                      curve: Curves.linear,
                    );
                  },
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        localizations.codeName,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        localizations.beginningBalance,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        localizations.postedDebits,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        localizations.postedCredits,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        localizations.endingBalance,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
      trailing: const Text(' '),
    );
  }
}
