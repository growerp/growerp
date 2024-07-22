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

import 'package:decimal/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_core/growerp_core.dart';

class GlAccountListItem extends StatelessWidget {
  const GlAccountListItem(
      {super.key, required this.glAccount, required this.index});

  final GlAccount glAccount;
  final int index;

  @override
  Widget build(BuildContext context) {
    final glAccountBloc = context.read<GlAccountBloc>();
    String postedBalance = glAccount.postedBalance == null ||
            glAccount.postedBalance.toString() == '0'
        ? ''
        : Constant.numberFormat.format(DecimalIntl(glAccount.postedBalance!));
    return ListTile(
      leading: CircleAvatar(
        child: Text(glAccount.accountCode == null
            ? '?'
            : glAccount.accountCode!.substring(0, 3)),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isPhone(context))
          Text(glAccount.accountName ?? '',
              textAlign: TextAlign.left, key: Key('name$index')),
        Row(
          children: <Widget>[
            if ((isLargerThanPhone(context) && glAccount.isDebit != null))
              Expanded(
                  child: Text(glAccount.accountCode ?? '',
                      key: Key('code$index'))),
            if ((isPhone(context) && glAccount.isDebit != null))
              Expanded(
                  child: Text(glAccount.accountCode ?? '',
                      key: Key('code$index'))),
            if (isLargerThanPhone(context))
              Expanded(
                  child: Text(glAccount.accountName ?? '',
                      key: Key('name$index'))),
            if (isPhone(context))
              Expanded(
                  child: glAccount.isDebit == true
                      ? Text(postedBalance,
                          textAlign: TextAlign.right, key: Key('isDebit$index'))
                      : const Text('')),
            if (isLargerThanPhone(context))
              Expanded(
                  child: Text(
                      "${glAccount.accountClass?.description ?? ''} "
                      "${glAccount.isDebit != null ? glAccount.isDebit! ? '(D)' : '(C)' : ' '} ",
                      key: Key('class$index'))),
            if (isLargerThanPhone(context))
              Expanded(
                  child: Text(glAccount.accountType?.description ?? '',
                      key: Key('type$index'))),
            if (isPhone(context) && glAccount.isDebit == null)
              Text(
                  "debit:${glAccount.postedDebits.toString()} "
                  "credit:${glAccount.postedCredits.toString()}",
                  key: Key('postedBalance$index')),
            if (isPhone(context))
              Expanded(
                  child: glAccount.isDebit == false
                      ? Text(postedBalance,
                          textAlign: TextAlign.right, key: Key('isDebit$index'))
                      : const Text('')),
            if (isLargerThanPhone(context))
              Expanded(
                  child: glAccount.isDebit == null
                      ? Text(glAccount.postedDebits.toString(),
                          textAlign: TextAlign.center)
                      : glAccount.isDebit == true
                          ? Text(postedBalance,
                              textAlign: TextAlign.right,
                              key: Key('postedBalance$index'))
                          : const Text('')),
            if (isLargerThanPhone(context))
              Expanded(
                  child: glAccount.isDebit == null
                      ? Text(glAccount.postedCredits.toString(),
                          textAlign: TextAlign.center)
                      : glAccount.isDebit == false
                          ? Text(postedBalance,
                              textAlign: TextAlign.right,
                              key: Key('postedBalance$index'))
                          : const Text('')),
          ],
        ),
      ]),
      onTap: () async {
        await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) => BlocProvider.value(
                value: glAccountBloc, child: GlAccountDialog(glAccount)));
      },
    );
  }
}
