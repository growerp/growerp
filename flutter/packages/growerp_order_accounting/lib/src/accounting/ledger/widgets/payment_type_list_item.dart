// ignore_for_file: unnecessary_string_interpolations

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
import 'package:responsive_framework/responsive_framework.dart';

class PaymentTypeListItem extends StatelessWidget {
  const PaymentTypeListItem(
      {super.key, required this.paymentType, required this.index});

  final PaymentType paymentType;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(paymentType.paymentTypeName.substring(3, 5)),
      ),
      title: Row(
        children: <Widget>[
          Expanded(
              child: Text("${paymentType.paymentTypeName}",
                  key: Key('name$index'))),
          Expanded(
              child: Text("${paymentType.accountCode}",
                  key: Key('accountCode$index'), textAlign: TextAlign.center)),
          Expanded(
              child: Text("${paymentType.accountName}",
                  key: Key('accountName$index'))),
        ],
      ),
    );
  }
}
