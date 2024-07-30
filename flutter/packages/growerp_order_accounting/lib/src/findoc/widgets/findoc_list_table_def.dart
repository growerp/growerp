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

TableData getTableData(Bloc bloc, String classificationId, BuildContext context,
    FinDoc item, int index) {
  String currencyId = context
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;

  List<TableRowContent> rowContent = [];
  if (isPhone(context)) {
    rowContent.add(TableRowContent(
        width: 10,
        name: const Padding(
          padding: EdgeInsets.fromLTRB(3, 3, 0, 0),
          child: Text("Short\nID"),
        ),
        value: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            item.pseudoId == null ? '' : item.pseudoId!.lastChar(3),
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        )));

    rowContent.add(TableRowContent(
        width: 60,
        name: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${item.docType} Id'),
            const SizedBox(width: 10),
            Text(classificationId == 'AppHotel' ? 'RsvDate' : 'CrDate'),
          ]),
          Text(item.sales ? 'Customer' : 'Supplier'),
          Row(
            children: [
              const Text('Status'),
              const SizedBox(width: 10),
              if (item.docType != FinDocType.shipment) const Text('Total'),
              const SizedBox(width: 10),
              const Text('#Items'),
            ],
          ),
        ]),
        value: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Text(item.pseudoId ?? '', key: Key('id$index')),
              const SizedBox(width: 10),
              Text(
                classificationId == 'AppHotel'
                    ? item.items[0].rentalFromDate != null
                        ? item.items[0].rentalFromDate
                            .toString()
                            .substring(0, 10)
                        : '???'
                    : "${item.creationDate?.toString().substring(0, 11)}",
                key: const Key('date'),
              ),
            ],
          ),
          Text(item.otherCompany?.name.truncate(20) ?? '',
              key: Key("otherUser$index")),
          Row(
            children: [
              Text(
                  classificationId == 'AppHotel'
                      ? item.status!.hotel
                      : item.status!.name,
                  key: Key("status$index")),
              const SizedBox(width: 10),
              if (item.docType != FinDocType.shipment)
                Text(item.grandTotal.currency(currencyId: currencyId),
                    key: Key("grandTotal$index")),
              if (item.docType != FinDocType.shipment)
                const SizedBox(width: 10),
              Text(item.items.length.toString(), key: Key("itemsLength$index")),
            ],
          ),
        ])));
  } else {
    rowContent.add(TableRowContent(
        width: 5,
        name: Text('${item.docType} Id'),
        value: Text(item.pseudoId ?? '', key: Key('id$index'))));
    rowContent.add(TableRowContent(
        width: 12,
        name: Text(
            classificationId == 'AppHotel' ? 'Reserv. Date' : 'Creation Date'),
        value: Text(
            classificationId == 'AppHotel' &&
                    item.items[0].rentalFromDate != null
                ? item.items[0].rentalFromDate.toString().substring(0, 10)
                : "${item.creationDate?.toString().substring(0, 11)}",
            key: Key("date$index"))));
    rowContent.add(TableRowContent(
        width: 20,
        name: Text(item.sales ? 'Customer' : 'Supplier'),
        value:
            Text(item.otherCompany?.name ?? '', key: Key("otherUser$index"))));
    if (item.docType != FinDocType.shipment) {
      rowContent.add(TableRowContent(
          width: 10,
          name: const Text(
            "Total",
            textAlign: TextAlign.right,
          ),
          value: Text(item.grandTotal.currency(currencyId: currencyId),
              textAlign: TextAlign.right, key: Key("grandTotal$index"))));
    }
    rowContent.add(TableRowContent(
        width: 10,
        name: const Text("Status"),
        value: Text(
            classificationId == 'AppHotel'
                ? item.status!.hotel
                : item.status!.name,
            key: Key("status$index"))));
    rowContent.add(TableRowContent(
        width: 10,
        name: const Text("Email Address"),
        value: Text(item.otherCompany?.email ?? item.otherUser?.email ?? '',
            key: Key("emailstatus$index"))));
  }

  rowContent.add(TableRowContent(
      width: 25,
      name: '',
      value: Row(children: [
        if (item.docType == FinDocType.order ||
            item.docType == FinDocType.invoice)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            key: Key('print$index'),
            icon: const Icon(Icons.print),
            tooltip: 'PDF/Print ${item.docType}',
            onPressed: () async {
              await Navigator.pushNamed(context, '/printer', arguments: item);
            },
          ),
        if (item.status != FinDocStatusVal.cancelled &&
            item.status != FinDocStatusVal.completed)
          IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              key: Key('delete$index'),
              icon: const Icon(Icons.delete_forever),
              tooltip: 'remove item',
              onPressed: () async {
                bool? result = await confirmDialog(
                    context, "delete ${item.pseudoId}?", "cannot be undone!");
                if (result == true) {
                  bloc.add(FinDocUpdate(
                      item.copyWith(status: FinDocStatusVal.cancelled)));
                }
              })
      ])));
  return TableData(
      rowHeight: isPhone(context) ? 63 : 20, rowContent: rowContent);
}

// general settings
var padding = const SpanPadding(trailing: 5, leading: 5);
SpanDecoration? getBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}
