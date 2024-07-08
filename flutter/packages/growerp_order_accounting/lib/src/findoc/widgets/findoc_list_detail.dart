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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

// field headers
List<dynamic> getItemFieldNames(
    {int? itemIndex,
    String? classificationId,
    FinDoc? item,
    BuildContext? context}) {
  bool isPhone = isAPhone(context);
  if (isPhone)
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(3, 3, 0, 0),
        child: Text("Short\nID"),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${item!.docType} Id'),
          SizedBox(width: 10),
          Text(classificationId == 'AppHotel' ? 'RsvDate' : 'CrDate'),
        ]),
        Text(item.sales ? 'Customer' : 'Supplier'),
        Row(
          children: [
            Text('Status'),
            SizedBox(width: 10),
            if (item.docType != FinDocType.shipment) Text('Total'),
            SizedBox(width: 10),
            Text('#Items'),
          ],
        ),
      ]),
      const Text(""),
    ];
  else
    return [
      Text('${item!.docType} Id'),
      Text(classificationId == 'AppHotel' ? 'Reserv. Date' : 'Creation Date'),
      Text(item.sales ? 'Customer' : 'Supplier'),
      if (item.docType != FinDocType.shipment)
        const Text(
          "Total",
          textAlign: TextAlign.right,
        ),
      const Text("Status"),
      const Text("Email Address"),
      const Text(""),
    ];
}

// field lengths perc of screenwidth can be larger than 100 %: horizontal
List<double> getItemFieldWidth(
    {int? itemIndex, FinDoc? item, BuildContext? context}) {
  if (isPhone(context))
    return [10, 55, 25];
  else
    return [
      5,
      12,
      20,
      if (item?.docType != FinDocType.shipment) 10,
      10,
      10,
      15,
    ];
}

// row height
double getRowHeight({BuildContext? context}) {
  return isPhone(context) ? 65 : 20;
}

// general settings
var padding = SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

// fields content, using strings index not required
// widgets also allowed, then index is used for the key on the widgets
List<dynamic> getItemFieldContent(FinDoc finDoc,
    {int? itemIndex, BuildContext? context}) {
  String classificationId = context!.read<String>();
  String currencyId = context
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;
  if (isPhone(context))
    return [
      CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Text(
          finDoc.pseudoId == null ? '' : finDoc.pseudoId!.lastChar(3),
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(finDoc.pseudoId ?? '', key: Key('id$itemIndex')),
            SizedBox(width: 10),
            Text(
              classificationId == 'AppHotel'
                  ? finDoc.items[0].rentalFromDate != null
                      ? finDoc.items[0].rentalFromDate
                          .toString()
                          .substring(0, 10)
                      : '???'
                  : "${finDoc.creationDate?.toString().substring(0, 11)}",
              key: Key('date'),
            ),
          ],
        ),
        Text(finDoc.otherCompany?.name.truncate(25) ?? '',
            key: Key("otherUser$itemIndex")),
        Row(
          children: [
            Text(
                finDoc.status != null
                    ? finDoc.displayStatus(classificationId)!
                    : '??',
                key: Key("status$itemIndex")),
            const SizedBox(width: 10),
            if (finDoc.docType != FinDocType.shipment)
              Text(finDoc.grandTotal.currency(currencyId: currencyId),
                  key: Key("grandTotal$itemIndex")),
            if (finDoc.docType != FinDocType.shipment)
              const SizedBox(width: 10),
            Text(finDoc.items.length.toString(),
                key: Key("itemsLength$itemIndex")),
          ],
        ),
      ]),
    ];
  else
    return [
      Text(finDoc.pseudoId ?? '', key: Key('id$itemIndex')),
      Text(classificationId == 'AppHotel' &&
              finDoc.items[0].rentalFromDate != null
          ? finDoc.items[0].rentalFromDate.toString().substring(0, 10)
          : "${finDoc.creationDate?.toString().substring(0, 11)}"),
      Text(finDoc.otherCompany?.name ?? '', key: Key("otherUser$itemIndex")),
      if (finDoc.docType != FinDocType.shipment)
        Text("${finDoc.grandTotal!.currency(currencyId: currencyId)}",
            textAlign: TextAlign.right, key: Key("grandTotal$itemIndex")),
      Text(finDoc.displayStatus(classificationId)!,
          key: Key("status$itemIndex")),
      Text(finDoc.otherCompany?.email ?? finDoc.otherUser?.email ?? '',
          key: Key("emailstatus$itemIndex")),
    ];
}

// buttons
List<Widget> getRowActionButtons({
  Bloc<dynamic, dynamic>? bloc,
  BuildContext? context,
  FinDoc? item,
  int? itemIndex,
}) {
  // order from the web better not touch when in prep
  if (item!.docType == FinDocType.order &&
      item.salesChannel == 'Web' &&
      item.status == FinDocStatusVal.inPreparation) return [];
  return [
    // pdf currently just available for invoice and order
    if ((item.docType == FinDocType.order ||
        item.docType == FinDocType.invoice))
      IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.all(0),
        key: Key('print$itemIndex'),
        icon: const Icon(Icons.print),
        tooltip: 'PDF/Print ${item.docType}',
        onPressed: () async {
          await Navigator.pushNamed(context!, '/printer', arguments: item);
        },
      ),
    if ((item.status != FinDocStatusVal.cancelled &&
        item.status != FinDocStatusVal.completed))
      IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.all(0),
          key: Key('delete$itemIndex'),
          icon: const Icon(Icons.delete_forever),
          tooltip: 'remove item',
          onPressed: () async {
            bool? result = await confirmDialog(
                context!, "delete ${item.pseudoId}?", "cannot be undone!");
            if (result == true) {
              bloc!.add(FinDocUpdate(
                  item.copyWith(status: FinDocStatusVal.cancelled)));
            }
          }),
  ];
}
