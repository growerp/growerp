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

import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class BalanceSummaryListItem extends StatelessWidget {
  const BalanceSummaryListItem(
      {super.key, required this.glAccount, required this.index});

  final GlAccount glAccount;
  final int index;

  @override
  Widget build(BuildContext context) {
    //   var repos = context.read<AccountingAPIRepository>();
    //   final balanceSummaryBloc = context.read<BalanceSummaryBloc>();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(
            glAccount.accountName!.isEmpty ? '?' : glAccount.accountName![0]),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
              flex: 2,
              child: Text("${glAccount.accountCode} ${glAccount.accountName}",
                  key: Key("code$index"))),
          Expanded(
              child: Text(
                  Constant.numberFormat.format(DecimalIntl(
                      Decimal.parse(glAccount.beginningBalance.toString()))),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text(
                  Constant.numberFormat.format(DecimalIntl(
                      Decimal.parse(glAccount.postedDebits.toString()))),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text(
                  Constant.numberFormat.format(DecimalIntl(
                      Decimal.parse(glAccount.postedCredits.toString()))),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text(
                  Constant.numberFormat.format(DecimalIntl(
                      Decimal.parse(glAccount.postedBalance.toString()))),
                  textAlign: TextAlign.right)),
        ],
      ),
      onTap: () async {
        /*          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) => RepositoryProvider.value(
                  value: repos,
                  child: BlocProvider.value(
                      value: balanceSummaryBloc,
                      child: BalanceSummaryDialog(balanceSummary))));
    */
      },
      /*       trailing: IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          onPressed: () {
            balanceSummaryBloc
                .add(BalanceSummaryDelete(balanceSummary.copyWith(image: null)));
          },
        )*/
    );
  }
}
