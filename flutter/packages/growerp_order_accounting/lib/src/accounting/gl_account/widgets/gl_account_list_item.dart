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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GlAccountListItem extends StatelessWidget {
  const GlAccountListItem(
      {Key? key, required this.glAccount, required this.index})
      : super(key: key);

  final GlAccount glAccount;
  final int index;

  @override
  Widget build(BuildContext context) {
    final glAccountBloc = context.read<GlAccountBloc>();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(glAccount.accountCode == null
            ? '?'
            : glAccount.accountCode!.substring(0, 3)),
      ),
      title: Column(children: [
        if (ResponsiveBreakpoints.of(context).isMobile)
          Text(glAccount.accountName ?? '', key: Key('name$index')),
        Row(
          children: <Widget>[
            Expanded(
                child:
                    Text(glAccount.accountCode ?? '', key: Key('code$index'))),
            if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
              Expanded(
                  child: Text(glAccount.accountName ?? '',
                      key: Key('name$index'))),
            Expanded(
                child: Text(glAccount.isDebit == true ? 'Debit' : 'Credit',
                    key: Key('isDebit$index'), textAlign: TextAlign.center)),
            if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
              Expanded(
                  child: Text(glAccount.accountClass?.description ?? '',
                      key: Key('class$index'))),
            if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
              Expanded(
                  child: Text(glAccount.accountType?.description ?? '',
                      key: Key('type$index'))),
            Expanded(
                child: Text(
                    glAccount.postedBalance == null
                        ? '0'
                        : glAccount.postedBalance.toString(),
                    key: Key('postedBalance$index'),
                    textAlign: TextAlign.center)),
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
