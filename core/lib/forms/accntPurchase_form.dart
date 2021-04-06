/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:core/templates/@templates.dart';
import 'package:models/@models.dart';
import '../acctMenuItem_data.dart';
import '@forms.dart';

class AccntPurchaseOrderForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      title: "Purchase & Payments",
      menu: acctMenuItems,
      mapItems: acctPurchaseMap,
      menuIndex: MENU_ACCTPURCHASE,
      tabIndex: 0,
    );
  }
}

List<MapItem> acctPurchaseMap = [
  MapItem(
    form: FinDocsForm(sales: false, docType: 'invoice'),
    label: "Purchase invoices",
    icon: Icon(Icons.home),
    floatButtonRoute: "/finDoc",
    floatButtonArgs: FormArguments(
        object: FinDoc(sales: false, docType: 'invoice', items: []),
        menuIndex: MENU_ACCTPURCHASE),
  ),
  MapItem(
    form: FinDocsForm(sales: false, docType: 'payment'),
    label: "Puchase payments",
    icon: Icon(Icons.home),
    floatButtonRoute: "/finDoc",
    floatButtonArgs: FormArguments(
        object: FinDoc(sales: false, docType: 'payment', items: []),
        menuIndex: MENU_ACCTPURCHASE),
  ),
];
