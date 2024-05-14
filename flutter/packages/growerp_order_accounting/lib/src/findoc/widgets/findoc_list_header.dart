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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

List<TableViewCell> getHeaderTiles(BuildContext context, FinDoc finDoc) {
  bool isPhone = isAPhone(context);
  String classificationId = context.read<String>();

  late List<Widget> tableCells;
  if (isPhone)
    tableCells = [
      CircleAvatar(
        //    radius: 20,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(Icons.search_sharp,
            size: 25, color: Theme.of(context).colorScheme.onSecondary),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${finDoc.docType} Id'),
          SizedBox(width: 10),
          Text(classificationId == 'AppHotel'
              ? 'Reserv. Date'
              : 'Creation Date'),
        ]),
        Text(finDoc.sales ? 'Customer' : 'Supplier'),
        Row(
          children: [
            Text('Status'),
            SizedBox(width: 10),
            if (finDoc.docType != FinDocType.shipment) Text('Total'),
            SizedBox(width: 10),
            Text('#Items'),
          ],
        ),
      ]),
      const Text(''),
    ];
  else
    tableCells = [
      Text('${finDoc.docType} Id'),
      Text(classificationId == 'AppHotel' ? 'Reserv. Date' : 'Creation Date'),
      Text(finDoc.sales ? 'Customer' : 'Supplier'),
      if (finDoc.docType != FinDocType.shipment)
        const Text(
          "Total",
          textAlign: TextAlign.right,
        ),
      const Text("Status"),
      const Text("Email Address"),
      const Text(""),
    ];

  List<TableViewCell> tableViewCells = [];
  for (int index = 0; index < tableCells.length; index++) {
    tableViewCells.add(TableViewCell(child: tableCells[index]));
  }
  return tableViewCells;
}

// general settings
var padding = SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

// column width
double getColumnWidth(int index, bool isPhone) {
  if (isPhone)
    switch (index) {
      case 0:
        return 40;
      case 1:
        return 250;
      default:
        return 100;
    }

  switch (index) {
    case 0:
      return 60;
    case 2:
      return 300;
    case 6:
      return 200;
    default:
      return 100;
  }
}

// row definition
TableSpan? buildRowSpan(
    int index, bool isPhone, int length, BuildContext context) {
  if (index >= length) return null;

  return TableSpan(
    padding: padding,
    backgroundDecoration: getBackGround(context, index),
    extent: FixedTableSpanExtent(isPhone ? 75 : 25),
    recognizerFactories: <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(),
        (TapGestureRecognizer t) => t.onTap = () => print('Tap row $index'),
      ),
    },
  );
}

// Column Definition
TableSpan? buildColumnSpan(int index, bool isPhone, BuildContext context) {
  if (isPhone && index > 2)
    return null;
  else if (index > 6) return null;
  return TableSpan(
    backgroundDecoration: getBackGround(context, index),
    extent: FixedTableSpanExtent(getColumnWidth(index, isPhone)),
    padding: padding,
  );
}
