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

class BalanceSheetItem extends StatelessWidget {
  const BalanceSheetItem(
      {super.key, required this.glAccount, required this.index});

  final GlAccount glAccount;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(
            glAccount.accountName!.isEmpty ? '?' : glAccount.accountName![0]),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
              child: Text("${glAccount.accountCode} ${glAccount.accountName}",
                  key: Key("code$index"))),
          Expanded(
              child: Text(glAccount.beginningBalance.toString(),
                  key: Key("openBalance$index"), textAlign: TextAlign.center)),
          Expanded(
              child: Text(glAccount.postedDebits.toString(),
                  key: Key("name$index"), textAlign: TextAlign.center)),
          Expanded(
              child: Text(glAccount.postedCredits.toString(),
                  key: Key("name$index"), textAlign: TextAlign.center)),
          Expanded(
              child: Text(glAccount.postedBalance.toString(),
                  key: Key("name$index"), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
